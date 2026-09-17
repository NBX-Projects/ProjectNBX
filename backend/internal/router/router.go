package router

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/handlers"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/swagger"
	"github.com/projectnbx/backend/internal/websocket"
)

type Router struct {
	cfg        *config.Config
	repo       repository.Repository
	jwtService *auth.JWTService
	hub        *websocket.Hub
	startTime  time.Time
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
		startTime:  time.Now(),
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
	liveKitWebhookHandler := handlers.NewLiveKitWebhookHandler(r.cfg.LiveKitAPIKey, r.cfg.LiveKitSecret, r.repo, r.hub)
	serverHandler := handlers.NewServerHandler(r.repo, r.hub)
	wsHandler := handlers.NewWSHandler(r.hub, r.jwtService, r.repo)
	webrtcHandler := handlers.NewWebRTCHandler(r.hub.ScreenShareService.GetTURNService())

	// Endpoint Raiz Público
	router.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/" {
			http.NotFound(w, req)
			return
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"app":         "ProjectNBX Backend API",
			"status":      "online",
			"version":     "1.0.0",
			"environment": "active",
			"docs":        "/swagger/",
			"health":      "/api/health",
			"time":        time.Now().Format(time.RFC3339),
		})
	}).Methods("GET", "OPTIONS")

	// Documentação Interativa Swagger UI & OpenAPI JSON
	router.HandleFunc("/swagger", func(w http.ResponseWriter, req *http.Request) {
		http.Redirect(w, req, "/swagger/", http.StatusMovedPermanently)
	})
	router.HandleFunc("/docs", func(w http.ResponseWriter, req *http.Request) {
		http.Redirect(w, req, "/swagger/", http.StatusMovedPermanently)
	})
	router.HandleFunc("/swagger/doc.json", swagger.HandlerJSON).Methods("GET", "OPTIONS")
	router.PathPrefix("/swagger/").HandlerFunc(swagger.HandlerUI).Methods("GET", "OPTIONS")

	// Health Checks Públicos
	router.HandleFunc("/health", r.handleHealthCheck).Methods("GET", "OPTIONS")
	router.HandleFunc("/api/health", r.handleHealthCheck).Methods("GET", "OPTIONS")

	// Endpoint WebSocket
	router.HandleFunc("/ws", wsHandler.ServeWS)

	// Rotas Públicas de Auth
	api := router.PathPrefix("/api").Subrouter()
	api.HandleFunc("/auth/register", authHandler.Register).Methods("POST", "OPTIONS")
	api.HandleFunc("/auth/login", authHandler.Login).Methods("POST", "OPTIONS")

	// Webhooks LiveKit SFU (Autenticado via assinatura HMAC/JWT do LiveKit)
	api.HandleFunc("/livekit/webhook", liveKitWebhookHandler.HandleWebhook).Methods("POST", "OPTIONS")

	// Proxy Reverso LiveKit SFU (HTTP & WebSocket para sinalização e validação WebRTC)
	liveKitProxy := r.setupLiveKitProxy(r.cfg.LiveKitURL)
	api.PathPrefix("/livekit/").Handler(liveKitProxy)
	api.HandleFunc("/livekit", liveKitProxy.ServeHTTP)
	router.PathPrefix("/livekit/").Handler(liveKitProxy)
	router.HandleFunc("/livekit", liveKitProxy.ServeHTTP)

	// Rotas Protegidas por Autenticação JWT
	protected := api.PathPrefix("").Subrouter()
	protected.Use(r.jwtAuthMiddleware)

	// Perfil
	protected.HandleFunc("/auth/me", authHandler.GetCurrentUser).Methods("GET", "OPTIONS")
	protected.HandleFunc("/users/me", authHandler.UpdateProfile).Methods("PUT", "OPTIONS")
	protected.HandleFunc("/users/me/password", authHandler.ChangePassword).Methods("PUT", "OPTIONS")

	// LiveKit Token
	protected.HandleFunc("/voice/token", liveKitHandler.GenerateToken).Methods("POST", "OPTIONS")

	// WebRTC P2P TURN Credentials (RFC 5766)
	protected.HandleFunc("/webrtc/turn-credentials", webrtcHandler.GetTURNCredentials).Methods("GET", "OPTIONS")
	protected.HandleFunc("/v1/webrtc/turn-credentials", webrtcHandler.GetTURNCredentials).Methods("GET", "OPTIONS")

	// Servidores & Canais
	protected.HandleFunc("/servers", serverHandler.ListServers).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers", serverHandler.CreateServer).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/{id}", serverHandler.GetServer).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels", serverHandler.ListChannels).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels", serverHandler.CreateChannel).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels/{channelId}/messages", serverHandler.ListMessages).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels/{channelId}/messages/{messageId}", serverHandler.UpdateMessage).Methods("PUT", "PATCH", "OPTIONS")
	protected.HandleFunc("/servers/{id}/channels/{channelId}/messages/{messageId}", serverHandler.DeleteMessage).Methods("DELETE", "OPTIONS")

	// Membros do Servidor & Convites
	protected.HandleFunc("/servers/{id}/members", serverHandler.ListMembers).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/members", serverHandler.AddMember).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/{id}/members/{userId}", serverHandler.RemoveMember).Methods("DELETE", "OPTIONS")
	protected.HandleFunc("/servers/{id}/join", serverHandler.JoinServer).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/join/{code}", serverHandler.JoinServer).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/{id}/invites", serverHandler.ListInvites).Methods("GET", "OPTIONS")
	protected.HandleFunc("/servers/{id}/invites", serverHandler.CreateInvite).Methods("POST", "OPTIONS")
	protected.HandleFunc("/servers/{id}/invites/{code}", serverHandler.DeleteInvite).Methods("DELETE", "OPTIONS")

	// Busca de Usuários
	protected.HandleFunc("/users/search", authHandler.SearchUsers).Methods("GET", "OPTIONS")


	// Auditoria
	protected.HandleFunc("/audit-logs", func(w http.ResponseWriter, req *http.Request) {
		source := models.AuditSource(req.URL.Query().Get("source"))
		logs, err := r.repo.ListAuditLogs(50, source)
		if err != nil {
			http.Error(w, `{"error":"Erro ao buscar logs de auditoria"}`, http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(logs)
	}).Methods("GET", "OPTIONS")

	// Fallback para rotas não encontradas com cabeçalhos CORS garantidos
	router.NotFoundHandler = r.corsMiddleware(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error": "Rota não encontrada",
			"path":  req.URL.Path,
		})
	}))

	return router
}

// Middlewares
func (r *Router) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		origin := req.Header.Get("Origin")
		if origin != "" {
			w.Header().Set("Access-Control-Allow-Origin", origin)
		} else if r.cfg.AllowedOrigins != "" && r.cfg.AllowedOrigins != "*" {
			w.Header().Set("Access-Control-Allow-Origin", r.cfg.AllowedOrigins)
		} else {
			w.Header().Set("Access-Control-Allow-Origin", "*")
		}
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
		w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, Origin, X-Requested-With")
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Max-Age", "86400")

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
		// Preflight OPTIONS requests should bypass JWT auth
		if req.Method == "OPTIONS" {
			next.ServeHTTP(w, req)
			return
		}

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

		ctx := auth.WithUserContext(req.Context(), claims.UserID, claims.Username)
		next.ServeHTTP(w, req.WithContext(ctx))
	})
}

// handleHealthCheck executa diagnóstico de conectividade com banco e serviços
func (r *Router) handleHealthCheck(w http.ResponseWriter, req *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	ctx, cancel := context.WithTimeout(req.Context(), 2*time.Second)
	defer cancel()

	dbStatus := "up"
	var dbLatencyMs float64
	startPing := time.Now()
	if err := r.repo.Ping(ctx); err != nil {
		dbStatus = "down"
		log.Printf("⚠️ Health check DB ping error: %v", err)
	} else {
		dbLatencyMs = float64(time.Since(startPing).Microseconds()) / 1000.0
	}

	overallStatus := "healthy"
	httpStatusCode := http.StatusOK
	if dbStatus == "down" {
		overallStatus = "degraded"
		httpStatusCode = http.StatusServiceUnavailable
	}

	w.WriteHeader(httpStatusCode)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    overallStatus,
		"app":       "ProjectNBX Backend",
		"version":   "1.0.0",
		"uptime":    time.Since(r.startTime).Round(time.Second).String(),
		"timestamp": time.Now().Format(time.RFC3339),
		"components": map[string]interface{}{
			"database": map[string]interface{}{
				"status":     dbStatus,
				"latency_ms": dbLatencyMs,
			},
			"livekit": map[string]interface{}{
				"status": "configured",
				"url":    r.cfg.LiveKitURL,
			},
			"websocket": map[string]interface{}{
				"status": "active",
			},
		},
	})
}

// setupLiveKitProxy configura o proxy reverso para encaminhar tráfego HTTP e WebSocket (WebRTC) ao LiveKit SFU
func (r *Router) setupLiveKitProxy(targetURLStr string) http.Handler {
	if strings.TrimSpace(targetURLStr) == "" {
		targetURLStr = "http://localhost:7880"
	}
	if strings.HasPrefix(targetURLStr, "ws://") {
		targetURLStr = "http://" + strings.TrimPrefix(targetURLStr, "ws://")
	} else if strings.HasPrefix(targetURLStr, "wss://") {
		targetURLStr = "https://" + strings.TrimPrefix(targetURLStr, "wss://")
	}
	targetURL, err := url.Parse(targetURLStr)
	if err != nil {
		log.Printf("⚠️ Erro ao parsear LIVEKIT_URL para proxy (%s): %v", targetURLStr, err)
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			http.Error(w, `{"error":"Configuração inválida de LIVEKIT_URL"}`, http.StatusInternalServerError)
		})
	}

	proxy := httputil.NewSingleHostReverseProxy(targetURL)
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		path := req.URL.Path
		if strings.HasPrefix(path, "/api/livekit") {
			path = strings.TrimPrefix(path, "/api/livekit")
		} else if strings.HasPrefix(path, "/livekit") {
			path = strings.TrimPrefix(path, "/livekit")
		}
		if path == "" || !strings.HasPrefix(path, "/") {
			path = "/" + path
		}
		req.URL.Path = path
		if req.URL.RawPath != "" {
			rawPath := req.URL.RawPath
			if strings.HasPrefix(rawPath, "/api/livekit") {
				rawPath = strings.TrimPrefix(rawPath, "/api/livekit")
			} else if strings.HasPrefix(rawPath, "/livekit") {
				rawPath = strings.TrimPrefix(rawPath, "/livekit")
			}
			if rawPath == "" || !strings.HasPrefix(rawPath, "/") {
				rawPath = "/" + rawPath
			}
			req.URL.RawPath = rawPath
		}
		req.Host = targetURL.Host
	}

	proxy.ModifyResponse = func(resp *http.Response) error {
		origin := resp.Request.Header.Get("Origin")
		if origin != "" {
			resp.Header.Set("Access-Control-Allow-Origin", origin)
		} else if r.cfg.AllowedOrigins != "" && r.cfg.AllowedOrigins != "*" {
			resp.Header.Set("Access-Control-Allow-Origin", r.cfg.AllowedOrigins)
		} else {
			resp.Header.Set("Access-Control-Allow-Origin", "*")
		}
		resp.Header.Set("Access-Control-Allow-Credentials", "true")
		resp.Header.Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
		resp.Header.Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, Origin, X-Requested-With")
		return nil
	}

	proxy.ErrorHandler = func(w http.ResponseWriter, req *http.Request, proxyErr error) {
		log.Printf("[LiveKit Proxy Error] %s %s: %v", req.Method, req.URL.Path, proxyErr)
		origin := req.Header.Get("Origin")
		if origin != "" {
			w.Header().Set("Access-Control-Allow-Origin", origin)
		} else {
			w.Header().Set("Access-Control-Allow-Origin", "*")
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusBadGateway)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error":   "LiveKit SFU indisponível ou inacessível no momento",
			"details": proxyErr.Error(),
		})
	}

	return proxy
}

