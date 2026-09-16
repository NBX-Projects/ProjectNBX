package main

import (
	"log"
	"net/http"

	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/database"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/router"
	"github.com/projectnbx/backend/internal/websocket"
)

func main() {
	log.Println("🚀 Iniciando ProjectNBX Backend em Go...")

	// 1. Carregar configurações
	cfg := config.LoadConfig()

	// 2. Conectar ao Banco de Dados PostgreSQL Real
	db, err := database.ConnectPostgres(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("❌ Falha crítica ao conectar ao PostgreSQL: %v", err)
	}
	defer db.Close()

	// 3. Executar Migrations SQL
	log.Printf("📦 Executando migrations do diretório '%s'...", cfg.MigrationsDir)
	if err := database.RunMigrations(db, cfg.MigrationsDir); err != nil {
		log.Fatalf("❌ Falha crítica ao aplicar migrations: %v", err)
	}

	// 4. Inicializar Repositório PostgreSQL
	repo := repository.NewPostgresRepository(db)

	// 5. Inicializar Serviço JWT
	jwtService := auth.NewJWTService(cfg.JWTSecret)

	// 6. Inicializar WebSocket Hub
	hub := websocket.NewHub(repo)
	go hub.Run()

	// 7. Configurar Rotas HTTP e Middlewares
	appRouter := router.NewRouter(cfg, repo, jwtService, hub)
	handler := appRouter.SetupRoutes()

	// 8. Subir Servidor HTTP
	addr := ":" + cfg.Port
	log.Printf("✨ Servidor HTTP & WebSocket escutando na porta %s", addr)
	log.Printf("🩺 Health Check disponível em: http://localhost:%s/api/health (ou /health)", cfg.Port)
	log.Printf("📖 Swagger UI disponível em: http://localhost:%s/swagger/ (ou /docs)", cfg.Port)
	log.Printf("🎙️ LiveKit SFU configurado para: %s (API Key: %s)", cfg.LiveKitURL, cfg.LiveKitAPIKey)

	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatalf("❌ Falha crítica ao iniciar servidor: %v", err)
	}
}
