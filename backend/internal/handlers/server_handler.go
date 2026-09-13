package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/websocket"
)

type ServerHandler struct {
	repo repository.Repository
	hub  *websocket.Hub
}

func NewServerHandler(repo repository.Repository, hub *websocket.Hub) *ServerHandler {
	return &ServerHandler{
		repo: repo,
		hub:  hub,
	}
}

func (h *ServerHandler) ListServers(w http.ResponseWriter, r *http.Request) {
	servers, err := h.repo.ListServers()
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar servidores"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(servers)
}

func (h *ServerHandler) CreateServer(w http.ResponseWriter, r *http.Request) {
	var req models.CreateServerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Name == "" {
		http.Error(w, `{"error":"Nome do servidor é obrigatório"}`, http.StatusBadRequest)
		return
	}

	userID, _ := r.Context().Value("user_id").(string)
	server := &models.Server{
		Name:    req.Name,
		IconURL: req.IconURL,
		OwnerID: userID,
	}

	if err := h.repo.CreateServer(server); err != nil {
		http.Error(w, `{"error":"Erro ao criar servidor"}`, http.StatusInternalServerError)
		return
	}

	// Cria canal #geral e canal de voz padrão
	_ = h.repo.CreateChannel(&models.Channel{
		ServerID: server.ID,
		Name:     "geral",
		Type:     models.ChannelTypeText,
		Position: 1,
	})
	_ = h.repo.CreateChannel(&models.Channel{
		ServerID: server.ID,
		Name:     "Voz Geral",
		Type:     models.ChannelTypeVoice,
		Position: 2,
	})

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(server)
}

func (h *ServerHandler) GetServer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	server, err := h.repo.GetServerByID(serverID)
	if err != nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

	channels, _ := h.repo.ListChannelsByServer(serverID)
	server.Channels = channels

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(server)
}

func (h *ServerHandler) ListChannels(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	channels, err := h.repo.ListChannelsByServer(serverID)
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar canais"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(channels)
}

func (h *ServerHandler) CreateChannel(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	var req models.CreateChannelRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Name == "" {
		http.Error(w, `{"error":"Nome do canal é obrigatório"}`, http.StatusBadRequest)
		return
	}

	channelType := req.Type
	if channelType == "" {
		channelType = models.ChannelTypeText
	}

	channel := &models.Channel{
		ServerID: serverID,
		Name:     req.Name,
		Type:     channelType,
	}

	if err := h.repo.CreateChannel(channel); err != nil {
		http.Error(w, `{"error":"Erro ao criar canal"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(channel)
}

func (h *ServerHandler) ListMessages(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	channelID := vars["channelId"]

	limit := 50
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	messages, err := h.repo.ListMessagesByChannel(channelID, limit)
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar mensagens"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(messages)
}

func (h *ServerHandler) SendMessage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	channelID := vars["channelId"]

	var req models.SendMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Content == "" {
		http.Error(w, `{"error":"Conteúdo da mensagem é obrigatório"}`, http.StatusBadRequest)
		return
	}

	userID, _ := r.Context().Value("user_id").(string)
	author, _ := h.repo.GetUserByID(userID)

	msg := &models.Message{
		ID:        uuid.New().String(),
		ChannelID: channelID,
		ServerID:  serverID,
		AuthorID:  userID,
		Author:    author,
		Content:   req.Content,
		CreatedAt: time.Now(),
	}

	if err := h.repo.CreateMessage(msg); err != nil {
		http.Error(w, `{"error":"Erro ao salvar mensagem"}`, http.StatusInternalServerError)
		return
	}

	// Broadcast via WebSocket
	payloadBytes, _ := json.Marshal(msg)
	h.hub.Broadcast <- &models.WSEvent{
		Type:      models.EventChatMessage,
		Payload:   payloadBytes,
		ChannelID: channelID,
		ServerID:  serverID,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(msg)
}
