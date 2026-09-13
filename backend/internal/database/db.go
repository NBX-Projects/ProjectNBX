package database

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/lib/pq"
)

// ConnectPostgres tenta conectar ao PostgreSQL com política de retry e healthcheck
func ConnectPostgres(databaseURL string) (*sql.DB, error) {
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("falha ao abrir driver postgres: %w", err)
	}

	// Configuração de Connection Pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Retry loop de até 15 tentativas (útil durante inicialização de containers)
	maxRetries := 15
	for i := 1; i <= maxRetries; i++ {
		err = db.Ping()
		if err == nil {
			log.Printf("✅ Conexão com PostgreSQL estabelecida com sucesso!")
			return db, nil
		}
		log.Printf("⏳ Aguardando PostgreSQL ficar pronto... (tentativa %d/%d): %v", i, maxRetries, err)
		time.Sleep(2 * time.Second)
	}

	return nil, fmt.Errorf("timeout ao aguardar conexão com PostgreSQL após %d tentativas: %w", maxRetries, err)
}
