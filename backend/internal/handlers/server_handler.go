package handlers

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"math/big"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/storage"
	"github.com/projectnbx/backend/internal/websocket"
)

const base62Chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

func generateShortCode(length int) string {
	b := make([]byte, length)
	for i := range b {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(base62Chars))))
		if err != nil {
			b[i] = base62Chars[i%len(base62Chars)]
		} else {
			b[i] = base62Chars[num.Int64()]
		}
	}
	return string(b)
}

type ServerHandler struct {
	repo    repository.Repository
	hub     *websocket.Hub
	storage storage.StorageService
}

func NewServerHandler(repo repository.Repository, hub *websocket.Hub, stor ...storage.StorageService) *ServerHandler {
	var s storage.StorageService
	if len(stor) > 0 {
		s = stor[0]
	}
	return &ServerHandler{
		repo:    repo,
		hub:     hub,
		storage: s,
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

	userID := auth.GetUserID(r.Context())
	server := &models.Server{
		Name:        req.Name,
		IconURL:     req.IconURL,
		OwnerID:     userID,
		IsPublic:    req.IsPublic,
		Description: req.Description,
		Category:    req.Category,
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

func (h *ServerHandler) UpdateServer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	userID := auth.GetUserID(r.Context())

	server, err := h.repo.GetServerByID(serverID)
	if err != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

	if server.OwnerID != userID {
		hasPerm, errP := h.repo.HasServerPermission(serverID, userID, "can_manage_roles")
		if errP != nil || !hasPerm {
			http.Error(w, `{"error":"Sem permissão para atualizar configurações do servidor"}`, http.StatusForbidden)
			return
		}
	}

	var req models.UpdateServerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Corpo da requisição inválido"}`, http.StatusBadRequest)
		return
	}

	if req.Name != nil && strings.TrimSpace(*req.Name) != "" {
		server.Name = strings.TrimSpace(*req.Name)
	}
	if req.IconURL != nil {
		server.IconURL = strings.TrimSpace(*req.IconURL)
	}
	if req.IsPublic != nil {
		server.IsPublic = *req.IsPublic
	}
	if req.Description != nil {
		server.Description = strings.TrimSpace(*req.Description)
	}
	if req.Category != nil && strings.TrimSpace(*req.Category) != "" {
		server.Category = strings.TrimSpace(*req.Category)
	}

	if err := h.repo.UpdateServer(server); err != nil {
		http.Error(w, `{"error":"Erro ao atualizar servidor"}`, http.StatusInternalServerError)
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

	userID := auth.GetUserID(r.Context())
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
	h.hub.BroadcastEvent(&models.WSEvent{
		Type:      models.EventMessageUpdate,
		Payload:   payloadBytes,
		ChannelID: channelID,
		ServerID:  serverID,
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedMsg)
}

func (h *ServerHandler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	channelID := vars["channelId"]
	messageID := vars["messageId"]

	userID := auth.GetUserID(r.Context())
	existing, err := h.repo.GetMessageByID(messageID)
	if err == nil && existing != nil {
		if existing.AuthorID != "" && userID != "" && existing.AuthorID != userID {
			server, errS := h.repo.GetServerByID(serverID)
			if errS != nil || server == nil || server.OwnerID != userID {
				http.Error(w, `{"error":"Sem permissão para excluir esta mensagem"}`, http.StatusForbidden)
				return
			}
		}

		// Se a mensagem possuía anexo de mídia, remove do Cloudinary ou armazenamento local
		if existing.MediaURL != "" && h.storage != nil {
			go func(mediaURL string) {
				ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
				defer cancel()
				_ = h.storage.Delete(ctx, mediaURL)
			}(existing.MediaURL)
		}
	}

	if err := h.repo.DeleteMessage(messageID); err != nil {
		http.Error(w, `{"error":"Erro ao excluir mensagem"}`, http.StatusInternalServerError)
		return
	}

	payloadBytes, _ := json.Marshal(map[string]string{"id": messageID})
	h.hub.BroadcastEvent(&models.WSEvent{
		Type:      models.EventMessageDelete,
		Payload:   payloadBytes,
		ChannelID: channelID,
		ServerID:  serverID,
	})

	w.WriteHeader(http.StatusNoContent)
}

func (h *ServerHandler) ListMembers(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	server, errS := h.repo.GetServerByID(serverID)
	if errS != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

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
	currentUserID := auth.GetUserID(r.Context())

	server, errS := h.repo.GetServerByID(serverID)
	if errS != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

	if currentUserID != "" && server.OwnerID != currentUserID {
		http.Error(w, `{"error":"Sem permissão para adicionar membros a este servidor"}`, http.StatusForbidden)
		return
	}

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

	role := "member"
	if server.OwnerID == targetUser.ID {
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
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(member)
}

func (h *ServerHandler) RemoveMember(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	targetUserID := vars["userId"]

	currentUserID := auth.GetUserID(r.Context())
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
	codeOrID := strings.TrimSpace(vars["id"])
	if codeOrID == "" {
		codeOrID = strings.TrimSpace(vars["code"])
	}

	currentUserID := auth.GetUserID(r.Context())
	if currentUserID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	var targetServerID string

	// 1. Tenta resolver como código curto de convite
	invite, err := h.repo.GetInviteByCode(codeOrID)
	if err == nil && invite != nil {
		if invite.IsExpired {
			http.Error(w, `{"error":"Código de convite expirado"}`, http.StatusBadRequest)
			return
		}
		if invite.IsExhausted {
			http.Error(w, `{"error":"Este convite já atingiu o limite máximo de utilizações"}`, http.StatusBadRequest)
			return
		}
		if err := h.repo.IncrementInviteUses(invite.Code); err != nil {
			http.Error(w, `{"error":"Este convite já atingiu o limite máximo de utilizações"}`, http.StatusBadRequest)
			return
		}
		targetServerID = invite.ServerID
	} else {
		// 2. Fallback de compatibilidade: tenta resolver como ServerID direto
		server, errS := h.repo.GetServerByID(codeOrID)
		if errS != nil || server == nil {
			http.Error(w, `{"error":"Código de convite inválido ou servidor não encontrado"}`, http.StatusNotFound)
			return
		}
		targetServerID = server.ID
	}

	if err := h.repo.AddServerMember(targetServerID, currentUserID); err != nil {
		http.Error(w, `{"error":"Erro ao ingressar no servidor"}`, http.StatusInternalServerError)
		return
	}

	updatedServer, err := h.repo.GetServerByID(targetServerID)
	if err != nil {
		http.Error(w, `{"error":"Erro ao carregar dados do servidor"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedServer)
}

// CreateInvite gera um novo código de convite temporário ou permanente
func (h *ServerHandler) CreateInvite(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	currentUserID := auth.GetUserID(r.Context())

	if currentUserID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	server, err := h.repo.GetServerByID(serverID)
	if err != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

	var req models.CreateInviteRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	code := generateShortCode(7)
	// Garante unicidade tentando gerar novamente se já existir
	for i := 0; i < 3; i++ {
		existing, _ := h.repo.GetInviteByCode(code)
		if existing == nil {
			break
		}
		code = generateShortCode(8)
	}

	maxUses := 0
	if req.MaxUses != nil && *req.MaxUses > 0 {
		maxUses = *req.MaxUses
	}

	var expiresAt *time.Time
	if req.MaxAgeSeconds != nil && *req.MaxAgeSeconds > 0 {
		exp := time.Now().Add(time.Duration(*req.MaxAgeSeconds) * time.Second)
		expiresAt = &exp
	}

	invite := &models.ServerInvite{
		Code:      code,
		ServerID:  serverID,
		CreatorID: currentUserID,
		MaxUses:   maxUses,
		UsesCount: 0,
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
	}

	if err := h.repo.CreateInvite(invite); err != nil {
		http.Error(w, `{"error":"Erro ao criar convite"}`, http.StatusInternalServerError)
		return
	}

	creator, _ := h.repo.GetUserByID(currentUserID)
	invite.Creator = creator

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(invite)
}

// ListInvites lista todos os convites gerados para um servidor
func (h *ServerHandler) ListInvites(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	server, err := h.repo.GetServerByID(serverID)
	if err != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

	invites, err := h.repo.ListServerInvites(serverID)
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar convites"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(invites)
}

// DeleteInvite revoga um convite existente
func (h *ServerHandler) DeleteInvite(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	code := vars["code"]
	currentUserID := auth.GetUserID(r.Context())

	if currentUserID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	invite, err := h.repo.GetInviteByCode(code)
	if err != nil || invite == nil {
		http.Error(w, `{"error":"Convite não encontrado"}`, http.StatusNotFound)
		return
	}

	server, errS := h.repo.GetServerByID(invite.ServerID)
	// Apenas o criador do convite ou o proprietário do servidor podem revogar
	if currentUserID != invite.CreatorID && (errS != nil || server == nil || server.OwnerID != currentUserID) {
		http.Error(w, `{"error":"Sem permissão para revogar este convite"}`, http.StatusForbidden)
		return
	}

	if err := h.repo.DeleteInvite(code); err != nil {
		http.Error(w, `{"error":"Erro ao revogar convite"}`, http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListPublicServers lista servidores públicos disponíveis para descoberta
func (h *ServerHandler) ListPublicServers(w http.ResponseWriter, r *http.Request) {
	currentUserID := auth.GetUserID(r.Context())
	servers, err := h.repo.ListPublicServers(currentUserID)
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar servidores públicos"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(servers)
}

// CreateJoinRequest submete pedido de entrada em servidor público
func (h *ServerHandler) CreateJoinRequest(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	currentUserID := auth.GetUserID(r.Context())

	if currentUserID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	server, err := h.repo.GetServerByID(serverID)
	if err != nil || server == nil {
		http.Error(w, `{"error":"Servidor não encontrado"}`, http.StatusNotFound)
		return
	}

	if !server.IsPublic {
		http.Error(w, `{"error":"Este servidor é privado e não aceita pedidos de entrada"}`, http.StatusBadRequest)
		return
	}

	var reqBody struct {
		Message string `json:"message"`
	}
	_ = json.NewDecoder(r.Body).Decode(&reqBody)

	joinReq := &models.ServerJoinRequest{
		ServerID: serverID,
		UserID:   currentUserID,
		Message:  reqBody.Message,
	}

	if err := h.repo.CreateJoinRequest(joinReq); err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusBadRequest)
		return
	}

	joinReq.User, _ = h.repo.GetUserByID(currentUserID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(joinReq)
}

// ListJoinRequests lista pedidos de entrada para moderadores
func (h *ServerHandler) ListJoinRequests(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	currentUserID := auth.GetUserID(r.Context())

	hasPerm, err := h.repo.HasServerPermission(serverID, currentUserID, "can_accept_join_requests")
	if err != nil || !hasPerm {
		http.Error(w, `{"error":"Sem permissão para visualizar pedidos de entrada"}`, http.StatusForbidden)
		return
	}

	status := r.URL.Query().Get("status")
	requests, err := h.repo.ListJoinRequests(serverID, status)
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar pedidos de entrada"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(requests)
}

// ReviewJoinRequest aprova ou rejeita pedido de entrada
func (h *ServerHandler) ReviewJoinRequest(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	requestID := vars["requestId"]
	currentUserID := auth.GetUserID(r.Context())

	hasPerm, err := h.repo.HasServerPermission(serverID, currentUserID, "can_accept_join_requests")
	if err != nil || !hasPerm {
		http.Error(w, `{"error":"Sem permissão para gerenciar pedidos de entrada"}`, http.StatusForbidden)
		return
	}

	var reqBody struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil || (reqBody.Status != "approved" && reqBody.Status != "rejected") {
		http.Error(w, `{"error":"Status inválido. Use 'approved' ou 'rejected'"}`, http.StatusBadRequest)
		return
	}

	if err := h.repo.ReviewJoinRequest(requestID, currentUserID, reqBody.Status); err != nil {
		http.Error(w, `{"error":"Erro ao processar pedido de entrada"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": reqBody.Status})
}

// ListRoles lista os cargos de um servidor
func (h *ServerHandler) ListRoles(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]

	roles, err := h.repo.ListServerRoles(serverID)
	if err != nil {
		http.Error(w, `{"error":"Erro ao listar cargos"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(roles)
}

// CreateRole cria um novo cargo com permissões
func (h *ServerHandler) CreateRole(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	currentUserID := auth.GetUserID(r.Context())

	hasPerm, err := h.repo.HasServerPermission(serverID, currentUserID, "can_manage_roles")
	if err != nil || !hasPerm {
		http.Error(w, `{"error":"Sem permissão para criar cargos"}`, http.StatusForbidden)
		return
	}

	var req models.CreateRoleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.Name) == "" {
		http.Error(w, `{"error":"Nome do cargo é obrigatório"}`, http.StatusBadRequest)
		return
	}

	if req.Color == 0 {
		req.Color = 4294334375 // 0xFFF5CBA7
	}
	if req.Permissions == nil {
		req.Permissions = make(map[string]bool)
	}

	role := &models.ServerRole{
		ServerID:    serverID,
		Name:        strings.TrimSpace(req.Name),
		Color:       req.Color,
		Position:    req.Position,
		Permissions: req.Permissions,
	}

	if err := h.repo.CreateRole(role); err != nil {
		http.Error(w, `{"error":"Erro ao criar cargo"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(role)
}

// UpdateRole atualiza cargo e suas permissões
func (h *ServerHandler) UpdateRole(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	roleID := vars["roleId"]
	currentUserID := auth.GetUserID(r.Context())

	hasPerm, err := h.repo.HasServerPermission(serverID, currentUserID, "can_manage_roles")
	if err != nil || !hasPerm {
		http.Error(w, `{"error":"Sem permissão para editar cargos"}`, http.StatusForbidden)
		return
	}

	var req models.CreateRoleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.Name) == "" {
		http.Error(w, `{"error":"Dados do cargo inválidos"}`, http.StatusBadRequest)
		return
	}

	role, err := h.repo.GetRoleByID(roleID)
	if err != nil || role == nil || role.ServerID != serverID {
		http.Error(w, `{"error":"Cargo não encontrado"}`, http.StatusNotFound)
		return
	}

	role.Name = strings.TrimSpace(req.Name)
	if req.Color != 0 {
		role.Color = req.Color
	}
	role.Position = req.Position
	if req.Permissions != nil {
		role.Permissions = req.Permissions
	}

	if err := h.repo.UpdateRole(role); err != nil {
		http.Error(w, `{"error":"Erro ao atualizar cargo"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(role)
}

// DeleteRole remove um cargo
func (h *ServerHandler) DeleteRole(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	roleID := vars["roleId"]
	currentUserID := auth.GetUserID(r.Context())

	hasPerm, err := h.repo.HasServerPermission(serverID, currentUserID, "can_manage_roles")
	if err != nil || !hasPerm {
		http.Error(w, `{"error":"Sem permissão para remover cargos"}`, http.StatusForbidden)
		return
	}

	role, err := h.repo.GetRoleByID(roleID)
	if err != nil || role == nil || role.ServerID != serverID {
		http.Error(w, `{"error":"Cargo não encontrado"}`, http.StatusNotFound)
		return
	}

	if err := h.repo.DeleteRole(roleID); err != nil {
		http.Error(w, `{"error":"Erro ao remover cargo"}`, http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// AssignMemberRole vincula um cargo a um membro
func (h *ServerHandler) AssignMemberRole(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	targetUserID := vars["userId"]
	roleID := vars["roleId"]
	currentUserID := auth.GetUserID(r.Context())

	hasPerm, err := h.repo.HasServerPermission(serverID, currentUserID, "can_manage_roles")
	if err != nil || !hasPerm {
		http.Error(w, `{"error":"Sem permissão para atribuir cargos"}`, http.StatusForbidden)
		return
	}

	if err := h.repo.AssignMemberRole(serverID, targetUserID, roleID); err != nil {
		http.Error(w, `{"error":"Erro ao atribuir cargo"}`, http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// RemoveMemberRole remove atribuição de cargo de um membro
func (h *ServerHandler) RemoveMemberRole(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	serverID := vars["id"]
	targetUserID := vars["userId"]
	roleID := vars["roleId"]
	currentUserID := auth.GetUserID(r.Context())

	hasPerm, err := h.repo.HasServerPermission(serverID, currentUserID, "can_manage_roles")
	if err != nil || !hasPerm {
		http.Error(w, `{"error":"Sem permissão para remover cargo do membro"}`, http.StatusForbidden)
		return
	}

	if err := h.repo.RemoveMemberRole(serverID, targetUserID, roleID); err != nil {
		http.Error(w, `{"error":"Erro ao remover cargo"}`, http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
