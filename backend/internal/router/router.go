package router

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/handlers"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/websocket"
)

type Router struct {
	cfg        *config.Config
	repo       repository.Repository
	jwtService *auth.JWTService
	hub        *websocket.Hub
}

func NewRouter(
	cfg *config.Config,
	repo repository.Repository,
	jwtService *auth.JWTService,
	hub *websocket.Hub,
) *Router {
	return &Router{
		cfg:        cfg,
		repo:       repo,
		jwtService: jwtService,
		hub:        hub,
	}
}

func (r *Router) SetupRoutes() http.Handler {
	router := mux.NewRouter()

	// Middlewares Globais
	router.Use(r.loggingMiddleware)
	router.Use(r.recoveryMiddleware)
	router.Use(r.corsMiddleware)

	// Instancia os handlers
	authHandler := handlers.NewAuthHandler(r.repo, r.jwtService)
	liveKitService := auth.NewLiveKitService(r.cfg.LiveKitAPIKey, r.cfg.LiveKitSecret)
	liveKitHandler := handlers.NewLiveKitHandler(liveKitService, r.repo, r.cfg)
	serverHandler := handlers.NewServerHandler(r.repo, r.hub)
	wsHandler := handlers.NewWSHandler(r.hub, r.jwtService, r.repo)

	// Health Check
	router.HandleFunc("/api/health", func(w http.ResponseWriter, req *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":    "healthy",
			"app":       "ProjectNBX Backend",
			"timestamp": time.Now().Format(time.RFC3339),
			"livekit":   r.cfg.LiveKitURL,
		})
	}).Methods("GET", "OPTIONS")

	// Endpoint WebSocket
	router.HandleFunc("/ws", wsHandler.ServeWS)

	// Rotas Públicas de Auth
	api := router.PathPrefix("/api").Subrouter()
	api.HandleFunc("/auth/register", authHandler.Register).Methods("POST", "OPTIONS")
	api.HandleFunc("/auth/login", authHandler.Login).Methods("POST", "OPTIONS")

	// Rotas Protegidas por Autenticação JWT
	protected := api.PathPrefix("").Subrouter()
	protected.Use(r.jwtAuthMiddleware)

	// Perfil
	protected.HandleFunc("/auth/me", authHandler.GetCurrentUser).Methods("GET", "OPTIONS")

	// LiveKit Token
	protected.HandleFunc("/voice/token", liveKitHandler.GenerateToken).Methods("POST", "OPTIONS")

	// Servidores & Canais
	protected.HandleFunc("/servers", serverHandler.ListServers).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers", serverHandler.CreateServer).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/{id}", serverHandler.GetServer).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels", serverHandler.ListChannels).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels", serverHandler.CreateChannel).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels/{channelId}/messages", serverHandler.ListMessages).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels/{channelId}/messages", serverHandler.SendMessage).Methods("POST", "OPTIONS")

	return router
}

// Middlewares
func (r *Router) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", r.cfg.AllowedOrigins)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
		w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		if req.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, req)
	})
}

func (r *Router) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, req)
		if req.URL.Path != "/api/health" {
			log.Printf("[HTTP] %s %s - %v", req.Method, req.URL.Path, time.Since(start))
		}
	})
}

func (r *Router) recoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("[Panic Recovered] %v", err)
				http.Error(w, `{"error":"Erro interno do servidor"}`, http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, req)
	})
}

func (r *Router) jwtAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		authHeader := req.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, `{"error":"Token de autorização ausente"}`, http.StatusUnauthorized)
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			http.Error(w, `{"error":"Formato de token inválido. Use 'Bearer <token>'"}`, http.StatusUnauthorized)
			return
		}

		claims, err := r.jwtService.ValidateToken(parts[1])
		if err != nil {
			http.Error(w, `{"error":"Token inválido ou expirado"}`, http.StatusUnauthorized)
			return
		}

		ctx := context.WithValue(req.Context(), "user_id", claims.UserID)
		ctx = context.WithValue(ctx, "username", claims.Username)
		next.ServeHTTP(w, req.WithContext(ctx))
	})
}
