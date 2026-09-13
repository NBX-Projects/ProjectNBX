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
	RoomName        string `json:"room_name"`
	ParticipantName string `json:"participant_name"`
	Identity        string `json:"identity"`
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

	// Se identity não foi informada explicitamente, tenta pegar do contexto JWT ou usa fallback
	identity := req.Identity
	participantName := req.ParticipantName

	if ctxUserID, ok := r.Context().Value("user_id").(string); ok && ctxUserID != "" {
		if identity == "" {
			identity = ctxUserID
		}
		if participantName == "" {
			if user, err := h.repo.GetUserByID(ctxUserID); err == nil {
				participantName = user.Username
			}
		}
	}

	if identity == "" {
		identity = "guest_" + req.RoomName
	}
	if participantName == "" {
		participantName = identity
	}

	token, err := h.liveKitService.GenerateVoiceToken(req.RoomName, identity, participantName)
	if err != nil {
		http.Error(w, `{"error":"Falha ao gerar token do LiveKit: `+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(TokenResponse{
		Token:     token,
		ServerURL: h.cfg.LiveKitURL,
		RoomName:  req.RoomName,
	})
}
