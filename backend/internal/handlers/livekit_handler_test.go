package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/repository"
)

func TestLiveKitHandler_GenerateToken(t *testing.T) {
	cfg := &config.Config{
		LiveKitURL:    "ws://localhost:7880",
		LiveKitAPIKey: "devkey",
		LiveKitSecret: "secret123456789012345678901234567890",
	}
	repo := repository.NewMemoryRepository()
	lkService := auth.NewLiveKitService(cfg.LiveKitAPIKey, cfg.LiveKitSecret)
	handler := NewLiveKitHandler(lkService, repo, cfg)

	// 1. Success case with voice channel v1 (seeded in memory_repo)
	body, _ := json.Marshal(TokenRequest{RoomName: "v1"})
	req := newAuthRequest("POST", "/api/voice/token", body, "usr_dev_1", nil)
	rr := httptest.NewRecorder()
	handler.GenerateToken(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d: %s", rr.Code, rr.Body.String())
	}

	var resp TokenResponse
	_ = json.NewDecoder(rr.Body).Decode(&resp)
	if resp.Token == "" || resp.ServerURL != cfg.LiveKitURL || resp.RoomName != "v1" {
		t.Errorf("Unexpected TokenResponse: %+v", resp)
	}

	// 2. Missing room_name
	reqBad := newAuthRequest("POST", "/api/voice/token", []byte(`{"room_name":""}`), "usr_dev_1", nil)
	rrBad := httptest.NewRecorder()
	handler.GenerateToken(rrBad, reqBad)

	if rrBad.Code != http.StatusBadRequest {
		t.Errorf("Expected 400 Bad Request, got %d", rrBad.Code)
	}

	// 3. Unauthenticated
	reqUnauth := httptest.NewRequest("POST", "/api/voice/token", bytes.NewReader(body))
	rrUnauth := httptest.NewRecorder()
	handler.GenerateToken(rrUnauth, reqUnauth)

	if rrUnauth.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized, got %d", rrUnauth.Code)
	}

	// 4. Channel not found
	bodyMissing, _ := json.Marshal(TokenRequest{RoomName: "chan_missing_999"})
	reqMissing := newAuthRequest("POST", "/api/voice/token", bodyMissing, "usr_dev_1", nil)
	rrMissing := httptest.NewRecorder()
	handler.GenerateToken(rrMissing, reqMissing)

	if rrMissing.Code != http.StatusNotFound {
		t.Errorf("Expected 404 Not Found, got %d", rrMissing.Code)
	}
}
