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

	// 2. Localizar diretório de migrations com fallback inteligente
	resolvedDir := migrationsDir
	if info, err := os.Stat(resolvedDir); err != nil || !info.IsDir() {
		candidates := []string{
			"migrations",
			"backend/migrations",
			"../migrations",
			"../../migrations",
			"./migrations",
		}
		for _, c := range candidates {
			if cinf, err := os.Stat(c); err == nil && cinf.IsDir() {
				resolvedDir = c
				break
			}
		}
	}

	files, err := os.ReadDir(resolvedDir)
	if err != nil {
		return fmt.Errorf("erro ao ler diretório de migrations (%s): %w", resolvedDir, err)
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
		filePath := filepath.Join(resolvedDir, file)
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

	log.Println("✨ Seed inicial de usuários de teste concluído com sucesso (sem dados mock de servidores)!")
	return nil
}
