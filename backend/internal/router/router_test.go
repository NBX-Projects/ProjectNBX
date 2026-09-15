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

	// Test Health Endpoint
	req := httptest.NewRequest("GET", "/api/health", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for /api/health, got %d", rr.Code)
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
}

