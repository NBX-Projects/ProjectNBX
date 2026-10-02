package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

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
	if err := cfg.Validate(); err != nil {
		log.Fatalf("Configuração inválida: %v", err)
	}

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
	log.Printf("🎙️ LiveKit SFU configurado para: %s", cfg.LiveKitURL)

	server := &http.Server{
		Addr:              addr,
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       120 * time.Second,
		MaxHeaderBytes:    1 << 20,
	}

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-shutdown
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		if err := server.Shutdown(ctx); err != nil {
			log.Printf("Falha ao encerrar servidor de forma controlada: %v", err)
		}
	}()

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("❌ Falha crítica ao iniciar servidor: %v", err)
	}
}
