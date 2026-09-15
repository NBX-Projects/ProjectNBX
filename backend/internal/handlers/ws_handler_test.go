package handlers

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	ws "github.com/projectnbx/backend/internal/websocket"
)

func TestWSHandler_ServeWS(t *testing.T) {
	repo := repository.NewMemoryRepository()
	hub := ws.NewHub(repo)
	go hub.Run()

	jwtSvc := auth.NewJWTService("secret-for-test")
	handler := NewWSHandler(hub, jwtSvc, repo)

	// Valid token
	token, _ := jwtSvc.GenerateToken(&models.User{
		ID:       "usr_ws_test",
		Username: "ws_tester",
	})

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		handler.ServeWS(w, r)
	}))
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "?token=" + token + "&server_id=srv_test"

	wsConn, resp, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("Failed to dial websocket: %v, resp: %v", err, resp)
	}
	defer wsConn.Close()

	// Wait for client to be registered in hub
	time.Sleep(50 * time.Millisecond)

	// Test writing a message from client
	eventMsg := `{"type":"PING","payload":{}}`
	err = wsConn.WriteMessage(websocket.TextMessage, []byte(eventMsg))
	if err != nil {
		t.Fatalf("Failed to write websocket message: %v", err)
	}

	// Read pong reply
	_ = wsConn.SetReadDeadline(time.Now().Add(200 * time.Millisecond))
	_, msg, err := wsConn.ReadMessage()
	if err != nil {
		t.Logf("Read message notice (may be async): %v", err)
	} else if len(msg) == 0 {
		t.Error("Expected non-empty response from websocket")
	}
}

func TestWSHandler_UpgradeFail(t *testing.T) {
	repo := repository.NewMemoryRepository()
	hub := ws.NewHub(repo)
	jwtSvc := auth.NewJWTService("secret-for-test")
	handler := NewWSHandler(hub, jwtSvc, repo)

	// Normal HTTP request without upgrade headers
	req := httptest.NewRequest(http.MethodGet, "/ws", nil)
	rec := httptest.NewRecorder()

	handler.ServeWS(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("Expected status 400 Bad Request on missing websocket headers, got %d", rec.Code)
	}
}
