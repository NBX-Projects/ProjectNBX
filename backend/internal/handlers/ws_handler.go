package handlers

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/repository"
	ws "github.com/projectnbx/backend/internal/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Permite conexões do Flutter Desktop, Web e Mobile
		return true
	},
}

type WSHandler struct {
	hub        *ws.Hub
	jwtService *auth.JWTService
	repo       repository.Repository
}

func NewWSHandler(hub *ws.Hub, jwtService *auth.JWTService, repo repository.Repository) *WSHandler {
	return &WSHandler{
		hub:        hub,
		jwtService: jwtService,
		repo:       repo,
	}
}

func (h *WSHandler) ServeWS(w http.ResponseWriter, r *http.Request) {
	tokenStr := r.URL.Query().Get("token")
	var userID = "guest_" + r.RemoteAddr
	var username = "Convidado"

	if tokenStr != "" {
		claims, err := h.jwtService.ValidateToken(tokenStr)
		if err == nil && claims != nil {
			userID = claims.UserID
			username = claims.Username
		}
	}

	serverID := r.URL.Query().Get("server_id")

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[WebSocket] Falha no upgrade da conexão: %v", err)
		return
	}

	client := &ws.Client{
		Hub:      h.hub,
		Conn:     conn,
		Send:     make(chan []byte, 256),
		UserID:   userID,
		Username: username,
		ServerID: serverID,
	}

	h.hub.Register <- client

	go client.WritePump()
	go client.ReadPump()
}
