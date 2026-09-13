package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// RunMigrations executa todos os scripts .up.sql pendentes
func RunMigrations(db *sql.DB, migrationsDir string) error {
	// 1. Criar tabela de controle de migrations se não existir
	createTableQuery := `
	CREATE TABLE IF NOT EXISTS schema_migrations (
		version VARCHAR(255) PRIMARY KEY,
		applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);`
	if _, err := db.Exec(createTableQuery); err != nil {
		return fmt.Errorf("erro ao criar tabela schema_migrations: %w", err)
	}

	// 2. Ler arquivos de migrations
	files, err := os.ReadDir(migrationsDir)
	if err != nil {
		return fmt.Errorf("erro ao ler diretório de migrations (%s): %w", migrationsDir, err)
	}

	var upFiles []string
	for _, f := range files {
		if !f.IsDir() && strings.HasSuffix(f.Name(), ".up.sql") {
			upFiles = append(upFiles, f.Name())
		}
	}
	sort.Strings(upFiles)

	// 3. Executar cada migration pendente
	for _, file := range upFiles {
		var exists bool
		err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM schema_migrations WHERE version = $1)", file).Scan(&exists)
		if err != nil {
			return fmt.Errorf("erro ao verificar status da migration %s: %w", file, err)
		}

		if exists {
			continue // Já aplicada
		}

		log.Printf("📦 Aplicando migration: %s...", file)
		filePath := filepath.Join(migrationsDir, file)
		content, err := os.ReadFile(filePath)
		if err != nil {
			return fmt.Errorf("erro ao ler arquivo %s: %w", file, err)
		}

		tx, err := db.Begin()
		if err != nil {
			return fmt.Errorf("erro ao iniciar transação para migration %s: %w", file, err)
		}

		if _, err := tx.Exec(string(content)); err != nil {
			tx.Rollback()
			return fmt.Errorf("falha ao executar SQL da migration %s: %w", file, err)
		}

		if _, err := tx.Exec("INSERT INTO schema_migrations (version) VALUES ($1)", file); err != nil {
			tx.Rollback()
			return fmt.Errorf("erro ao registrar migration %s na tabela de controle: %w", file, err)
		}

		if err := tx.Commit(); err != nil {
			return fmt.Errorf("erro ao commitar migration %s: %w", file, err)
		}

		log.Printf("✅ Migration %s aplicada com sucesso!", file)
	}

	// 4. Seed de dados iniciais se banco estiver vazio
	if err := SeedInitialData(db); err != nil {
		log.Printf("⚠️ Aviso durante seed inicial: %v", err)
	}

	return nil
}

// SeedInitialData insere usuários e servidores de demonstração se a tabela estiver vazia
func SeedInitialData(db *sql.DB) error {
	var userCount int
	if err := db.QueryRow("SELECT COUNT(*) FROM users").Scan(&userCount); err != nil {
		return err
	}

	if userCount > 0 {
		return nil // Banco já possui dados
	}

	log.Println("🌱 Populando banco com dados iniciais (Seed)...")

	// Usuário 1: DevNBX (dev@nbx.com / senha_segura_123)
	devHash, _ := bcrypt.GenerateFromPassword([]byte("senha_segura_123"), bcrypt.DefaultCost)
	_, err := db.Exec(`
		INSERT INTO users (id, username, email, password, avatar_url, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (email) DO NOTHING`,
		"usr_dev_1",
		"DevNBX",
		"dev@nbx.com",
		string(devHash),
		"https://api.dicebear.com/7.x/bottts/svg?seed=taui",
		"online",
		time.Now(),
		time.Now(),
	)
	if err != nil {
		return fmt.Errorf("erro ao criar usuário DevNBX: %w", err)
	}

	// Usuário 2: DarkLord_X (dev@projectnbx.com / admin123)
	adminHash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	_, err = db.Exec(`
		INSERT INTO users (id, username, email, password, avatar_url, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (email) DO NOTHING`,
		"usr_dev_2",
		"DarkLord_X",
		"dev@projectnbx.com",
		string(adminHash),
		"https://api.dicebear.com/7.x/bottts/svg?seed=nbxdev",
		"online",
		time.Now(),
		time.Now(),
	)
	if err != nil {
		return fmt.Errorf("erro ao criar usuário DarkLord_X: %w", err)
	}

	// Servidores e canais padrão
	seedServers := []struct {
		ID       string
		Name     string
		Banner   string
		Channels []struct {
			ID   string
			Name string
			Type string
		}
	}{
		{
			ID:     "srv_1",
			Name:   "Apex Predators",
			Banner: "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type string
			}{
				{"chn_t1", "geral", "text"},
				{"chn_t2", "anúncios", "text"},
				{"chn_v1", "Ranked Match", "voice"},
			},
		},
		{
			ID:     "srv_2",
			Name:   "Dev Lounge",
			Banner: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type string
			}{
				{"chn_t3", "geral", "text"},
				{"chn_v2", "Code Review", "voice"},
			},
		},
	}

	for _, s := range seedServers {
		_, err := db.Exec(`
			INSERT INTO servers (id, name, icon_url, owner_id, member_count, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			ON CONFLICT (id) DO NOTHING`,
			s.ID, s.Name, s.Banner, "usr_dev_1", 100, time.Now(), time.Now(),
		)
		if err != nil {
			continue
		}

		for pos, c := range s.Channels {
			_, _ = db.Exec(`
				INSERT INTO channels (id, server_id, name, type, position, created_at, updated_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
				ON CONFLICT (id) DO NOTHING`,
				c.ID, s.ID, c.Name, c.Type, pos+1, time.Now(), time.Now(),
			)
		}
	}

	// Mensagem de boas-vindas
	_, _ = db.Exec(`
		INSERT INTO messages (id, channel_id, server_id, author_id, content, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (id) DO NOTHING`,
		"msg_"+uuid.New().String(), "chn_t1", "srv_1", "usr_dev_1",
		"Bem-vindo ao ProjectNBX com PostgreSQL! 🚀", time.Now(),
	)

	log.Println("✨ Seed inicial concluído com sucesso!")
	return nil
}
