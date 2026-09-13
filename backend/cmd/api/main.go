package main

import (
	"log"
	"net/http"

	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/router"
	"github.com/projectnbx/backend/internal/websocket"
)

func main() {
	log.Println("🚀 Iniciando ProjectNBX Backend em Go...")

	// 1. Carregar configurações
	cfg := config.LoadConfig()

	// 2. Inicializar Repositório de Dados
	repo := repository.NewMemoryRepository()

	// 3. Inicializar Serviço JWT
	jwtService := auth.NewJWTService(cfg.JWTSecret)

	// 4. Inicializar WebSocket Hub
	hub := websocket.NewHub(repo)
	go hub.Run()

	// 5. Configurar Rotas HTTP e Middlewares
	appRouter := router.NewRouter(cfg, repo, jwtService, hub)
	handler := appRouter.SetupRoutes()

	// 6. Subir Servidor HTTP
	addr := ":" + cfg.Port
	log.Printf("✨ Servidor HTTP & WebSocket escutando na porta %s", addr)
	log.Printf("🎙️ LiveKit SFU configurado para: %s (API Key: %s)", cfg.LiveKitURL, cfg.LiveKitAPIKey)

	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatalf("❌ Falha crítica ao iniciar servidor: %v", err)
	}
}
