package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/repository"
)

type LiveKitHandler struct {
	liveKitService *auth.LiveKitService
	repo           repository.Repository
	cfg            *config.Config
}

func NewLiveKitHandler(liveKitService *auth.LiveKitService, repo repository.Repository, cfg *config.Config) *LiveKitHandler {
	return &LiveKitHandler{
		liveKitService: liveKitService,
		repo:           repo,
		cfg:            cfg,
	}
}

type TokenRequest struct {
	RoomName string `json:"room_name"`
}

type TokenResponse struct {
	Token     string `json:"token"`
	ServerURL string `json:"server_url"`
	RoomName  string `json:"room_name"`
}

func (h *LiveKitHandler) GenerateToken(w http.ResponseWriter, r *http.Request) {
	var req TokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.RoomName == "" {
		http.Error(w, `{"error":"'room_name' é obrigatório"}`, http.StatusBadRequest)
		return
	}

	// 1. Validação estrita de autenticação JWT
	ctxUserID, ok := r.Context().Value("user_id").(string)
	if !ok || ctxUserID == "" {
		http.Error(w, `{"error":"Não autenticado"}`, http.StatusUnauthorized)
		return
	}

	// 2. Busca o canal pelo RoomName (ChannelID)
	channel, err := h.repo.GetChannelByID(req.RoomName)
	if err != nil || channel == nil {
		http.Error(w, `{"error":"Canal de voz não encontrado"}`, http.StatusNotFound)
		return
	}

	// 3. Garante que o usuário faça parte dos membros do servidor comunitário
	if channel.ServerID != "" {
		isMember, _ := h.repo.IsServerMember(channel.ServerID, ctxUserID)
		if !isMember {
			_ = h.repo.AddServerMember(channel.ServerID, ctxUserID)
		}
	}

	// 5. Garante que identity seja a identidade do usuário autenticado (impede spoofing)
	user, err := h.repo.GetUserByID(ctxUserID)
	participantName := ctxUserID
	if err == nil && user != nil && user.Username != "" {
		participantName = user.Username
	}

	token, err := h.liveKitService.GenerateVoiceToken(channel.ID, ctxUserID, participantName)
	if err != nil {
		http.Error(w, `{"error":"Falha ao gerar token do LiveKit: `+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(TokenResponse{
		Token:     token,
		ServerURL: h.cfg.LiveKitURL,
		RoomName:  channel.ID,
	})
}
