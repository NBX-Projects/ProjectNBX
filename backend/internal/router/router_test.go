package router

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/websocket"
)

func TestRouter_SetupRoutes(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:      "test-secret",
		LiveKitAPIKey:  "key",
		LiveKitSecret:  "secret",
		AllowedOrigins: "*",
	}
	repo := repository.NewMemoryRepository()
	jwtService := auth.NewJWTService(cfg.JWTSecret)
	hub := websocket.NewHub(nil)

	r := NewRouter(cfg, repo, jwtService, hub)
	handler := r.SetupRoutes()

	if handler == nil {
		t.Fatal("Expected non-nil HTTP handler from SetupRoutes")
	}

	// Test Health Endpoint (/api/health)
	req := httptest.NewRequest("GET", "/api/health", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for /api/health, got %d", rr.Code)
	}

	// Test Public Alias Health Endpoint (/health)
	healthReq := httptest.NewRequest("GET", "/health", nil)
	healthRR := httptest.NewRecorder()
	handler.ServeHTTP(healthRR, healthReq)

	if healthRR.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for /health, got %d", healthRR.Code)
	}

	// Test Public Root Endpoint (/)
	rootReq := httptest.NewRequest("GET", "/", nil)
	rootRR := httptest.NewRecorder()
	handler.ServeHTTP(rootRR, rootReq)

	if rootRR.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for /, got %d", rootRR.Code)
	}

	// Test Swagger UI Endpoint (/swagger/)
	swaggerReq := httptest.NewRequest("GET", "/swagger/", nil)
	swaggerRR := httptest.NewRecorder()
	handler.ServeHTTP(swaggerRR, swaggerReq)

	if swaggerRR.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for /swagger/, got %d", swaggerRR.Code)
	}

	// Test Swagger JSON Spec (/swagger/doc.json)
	jsonReq := httptest.NewRequest("GET", "/swagger/doc.json", nil)
	jsonRR := httptest.NewRecorder()
	handler.ServeHTTP(jsonRR, jsonReq)

	if jsonRR.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for /swagger/doc.json, got %d", jsonRR.Code)
	}

	// Test Docs Redirect (/docs)
	docsReq := httptest.NewRequest("GET", "/docs", nil)
	docsRR := httptest.NewRecorder()
	handler.ServeHTTP(docsRR, docsReq)

	if docsRR.Code != http.StatusMovedPermanently {
		t.Errorf("Expected status 301 Moved Permanently for /docs, got %d", docsRR.Code)
	}

	// Test CORS Preflight
	optReq := httptest.NewRequest("OPTIONS", "/api/servers", nil)
	optRR := httptest.NewRecorder()
	handler.ServeHTTP(optRR, optReq)

	if optRR.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for OPTIONS, got %d", optRR.Code)
	}

	// Test Protected Route without token
	protReq := httptest.NewRequest("GET", "/api/servers", nil)
	protRR := httptest.NewRecorder()
	handler.ServeHTTP(protRR, protReq)

	if protRR.Code != http.StatusUnauthorized {
		t.Errorf("Expected status 401 Unauthorized for /api/servers without token, got %d", protRR.Code)
	}

	// Test Protected Route with valid token
	user := &models.User{
		ID:       "usr_dev_1",
		Username: "DarkLord_X",
		Email:    "dev@projectnbx.com",
	}
	token, err := jwtService.GenerateToken(user)
	if err != nil {
		t.Fatalf("Failed to generate test token: %v", err)
	}

	authReq := httptest.NewRequest("GET", "/api/servers", nil)
	authReq.Header.Set("Authorization", "Bearer "+token)
	authRR := httptest.NewRecorder()
	handler.ServeHTTP(authRR, authReq)

	if authRR.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for /api/servers with token, got %d: %s", authRR.Code, authRR.Body.String())
	}

	// Test LiveKit Preflight OPTIONS (/api/livekit/rtc/validate)
	lkOptReq := httptest.NewRequest("OPTIONS", "/api/livekit/rtc/validate", nil)
	lkOptReq.Header.Set("Origin", "https://nbx-projects.github.io")
	lkOptRR := httptest.NewRecorder()
	handler.ServeHTTP(lkOptRR, lkOptReq)

	if lkOptRR.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for LiveKit OPTIONS, got %d", lkOptRR.Code)
	}
	if origin := lkOptRR.Header().Get("Access-Control-Allow-Origin"); origin != "https://nbx-projects.github.io" && origin != "*" {
		t.Errorf("Expected CORS origin header, got %s", origin)
	}

	// Test 404 NotFoundHandler with CORS
	nfReq := httptest.NewRequest("GET", "/api/rota_inexistente", nil)
	nfReq.Header.Set("Origin", "https://nbx-projects.github.io")
	nfRR := httptest.NewRecorder()
	handler.ServeHTTP(nfRR, nfReq)

	if nfRR.Code != http.StatusNotFound {
		t.Errorf("Expected status 404 for unknown route, got %d", nfRR.Code)
	}
	if origin := nfRR.Header().Get("Access-Control-Allow-Origin"); origin == "" {
		t.Errorf("Expected CORS header on 404 response, got empty")
	}
}

func TestRouter_LiveKitProxy(t *testing.T) {
	// Mock LiveKit backend server
	var receivedPath string
	var receivedQuery string
	mockLiveKit := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		receivedPath = req.URL.Path
		receivedQuery = req.URL.RawQuery
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"validated"}`))
	}))
	defer mockLiveKit.Close()

	cfg := &config.Config{
		JWTSecret:      "test-secret",
		LiveKitURL:     mockLiveKit.URL,
		AllowedOrigins: "*",
	}
	repo := repository.NewMemoryRepository()
	jwtService := auth.NewJWTService(cfg.JWTSecret)
	hub := websocket.NewHub(nil)

	r := NewRouter(cfg, repo, jwtService, hub)
	handler := r.SetupRoutes()

	// Test forwarding to /api/livekit/rtc/validate?token=123
	req := httptest.NewRequest("GET", "/api/livekit/rtc/validate?token=123", nil)
	req.Header.Set("Origin", "https://nbx-projects.github.io")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected status 200 OK from LiveKit proxy, got %d", rr.Code)
	}
	if receivedPath != "/rtc/validate" {
		t.Errorf("Expected path /rtc/validate at LiveKit, got %s", receivedPath)
	}
	if receivedQuery != "token=123" {
		t.Errorf("Expected query token=123, got %s", receivedQuery)
	}
	if origin := rr.Header().Get("Access-Control-Allow-Origin"); origin != "https://nbx-projects.github.io" && origin != "*" {
		t.Errorf("Expected CORS header on proxy response, got %s", origin)
	}

	// Test direct /livekit prefix forwarding without /api
	reqDirect := httptest.NewRequest("GET", "/livekit/rtc/validate?direct=true", nil)
	rrDirect := httptest.NewRecorder()
	handler.ServeHTTP(rrDirect, reqDirect)

	if rrDirect.Code != http.StatusOK {
		t.Fatalf("Expected status 200 OK from /livekit direct proxy, got %d", rrDirect.Code)
	}
	if receivedPath != "/rtc/validate" {
		t.Errorf("Expected path /rtc/validate at LiveKit for direct proxy, got %s", receivedPath)
	}
}


