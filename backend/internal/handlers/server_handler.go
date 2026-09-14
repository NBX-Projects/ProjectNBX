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
	chnText := &models.Channel{
		ServerID: server.ID,
		Name:     "geral",
		Type:     models.ChannelTypeText,
		Position: 1,
	}
	_ = h.repo.CreateChannel(chnText)

	chnVoice := &models.Channel{
		ServerID: server.ID,
		Name:     "Voz Geral",
		Type:     models.ChannelTypeVoice,
		Position: 2,
	}
	_ = h.repo.CreateChannel(chnVoice)

	server.Channels = []*models.Channel{chnText, chnVoice}

	// Registrar log de auditoria
	_ = h.repo.CreateAuditLog(&models.AuditLog{
		ID:        uuid.New().String(),
		UserID:    &userID,
		Action:    "SERVER_CREATED",
		Source:    models.AuditSourceServer,
		IPAddress: r.RemoteAddr,
		UserAgent: r.UserAgent(),
		Metadata: map[string]interface{}{
			"server_id":   server.ID,
			"server_name": server.Name,
		},
		CreatedAt: time.Now(),
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

func (h *ServerHandler) UpdateMessage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	channelID := vars["channelId"]
	messageID := vars["messageId"]

	var req models.UpdateMessageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Content == "" {
		http.Error(w, `{"error":"Conteúdo da mensagem é obrigatório"}`, http.StatusBadRequest)
		return
	}

	userID, _ := r.Context().Value("user_id").(string)
	existing, err := h.repo.GetMessageByID(messageID)
	if err == nil && existing != nil && existing.AuthorID != "" && userID != "" && existing.AuthorID != userID {
		http.Error(w, `{"error":"Sem permissão para editar esta mensagem"}`, http.StatusForbidden)
		return
	}

	if err := h.repo.UpdateMessage(messageID, req.Content); err != nil {
		http.Error(w, `{"error":"Erro ao atualizar mensagem"}`, http.StatusInternalServerError)
		return
	}

	updatedMsg := &models.Message{
		ID:        messageID,
		ChannelID: channelID,
		ServerID:  serverID,
		Content:   req.Content,
		IsEdited:  true,
		UpdatedAt: time.Now(),
	}
	if existing != nil {
		updatedMsg.AuthorID = existing.AuthorID
		updatedMsg.Author = existing.Author
		updatedMsg.CreatedAt = existing.CreatedAt
	}

	payloadBytes, _ := json.Marshal(updatedMsg)
	h.hub.Broadcast <- &models.WSEvent{
		Type:      models.EventMessageUpdate,
		Payload:   payloadBytes,
		ChannelID: channelID,
		ServerID:  serverID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedMsg)
}

func (h *ServerHandler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	channelID := vars["channelId"]
	messageID := vars["messageId"]

	userID, _ := r.Context().Value("user_id").(string)
	existing, err := h.repo.GetMessageByID(messageID)
	if err == nil && existing != nil && existing.AuthorID != "" && userID != "" && existing.AuthorID != userID {
		server, errS := h.repo.GetServerByID(serverID)
		if errS != nil || server == nil || server.OwnerID != userID {
			http.Error(w, `{"error":"Sem permissão para excluir esta mensagem"}`, http.StatusForbidden)
			return
		}
	}

	if err := h.repo.DeleteMessage(messageID); err != nil {
		http.Error(w, `{"error":"Erro ao excluir mensagem"}`, http.StatusInternalServerError)
		return
	}

	payloadBytes, _ := json.Marshal(map[string]string{"id": messageID})
	h.hub.Broadcast <- &models.WSEvent{
		Type:      models.EventMessageDelete,
		Payload:   payloadBytes,
		ChannelID: channelID,
		ServerID:  serverID,
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *ServerHandler) ListMembers(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	members, err := h.repo.ListServerMembers(serverID)
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar membros do servidor"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(members)
}

func (h *ServerHandler) AddMember(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	var req models.AddMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Payload inválido"}`, http.StatusBadRequest)
		return
	}

	var targetUser *models.User
	var err error

	if req.UserID != "" {
		targetUser, err = h.repo.GetUserByID(req.UserID)
	} else if req.Email != "" {
		targetUser, err = h.repo.GetUserByEmail(req.Email)
	} else if req.Username != "" {
		targetUser, err = h.repo.FindUser(req.Username)
	}

	if err != nil || targetUser == nil {
		http.Error(w, `{"error":"Usuário não encontrado. Verifique o nome de usuário ou e-mail digitado."}`, http.StatusNotFound)
		return
	}

	if err := h.repo.AddServerMember(serverID, targetUser.ID); err != nil {
		http.Error(w, `{"error":"Erro ao adicionar membro ao servidor"}`, http.StatusInternalServerError)
		return
	}

	server, _ := h.repo.GetServerByID(serverID)
	role := "member"
	if server != nil && server.OwnerID == targetUser.ID {
		role = "owner"
	}

	member := &models.ServerMember{
		ServerID: serverID,
		UserID:   targetUser.ID,
		User:     targetUser,
		Role:     role,
		JoinedAt: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(member)
}

func (h *ServerHandler) RemoveMember(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	targetUserID := vars["userId"]

	currentUserID, _ := r.Context().Value("user_id").(string)
	server, err := h.repo.GetServerByID(serverID)
	if err != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

	// Only owner can remove others, or user can leave themselves
	if currentUserID != server.OwnerID && currentUserID != targetUserID {
		http.Error(w, `{"error":"Permissão negada para remover membro"}`, http.StatusForbidden)
		return
	}

	if err := h.repo.RemoveServerMember(serverID, targetUserID); err != nil {
		http.Error(w, `{"error":"Erro ao remover membro"}`, http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *ServerHandler) JoinServer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	currentUserID, _ := r.Context().Value("user_id").(string)

	if currentUserID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	server, err := h.repo.GetServerByID(serverID)
	if err != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado com o código fornecido"}`, http.StatusNotFound)
		return
	}

	if err := h.repo.AddServerMember(serverID, currentUserID); err != nil {
		http.Error(w, `{"error":"Erro ao ingressar no servidor"}`, http.StatusInternalServerError)
		return
	}

	updatedServer, err := h.repo.GetServerByID(serverID)
	if err != nil {
		updatedServer = server
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedServer)
}
