package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
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

	return nil
}
