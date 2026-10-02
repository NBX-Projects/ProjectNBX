package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	lkauth "github.com/livekit/protocol/auth"
	"github.com/projectnbx/backend/config"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/repository"
)

type ScreenIngressHandler struct {
	repo repository.Repository
	cfg  *config.Config
}

func NewScreenIngressHandler(repo repository.Repository, cfg *config.Config) *ScreenIngressHandler {
	return &ScreenIngressHandler{repo: repo, cfg: cfg}
}

type createScreenIngressRequest struct {
	ChannelID string `json:"channel_id"`
}

type createIngressAPIRequest struct {
	InputType           int    `json:"inputType"`
	Name                string `json:"name"`
	RoomName            string `json:"roomName"`
	ParticipantIdentity string `json:"participantIdentity"`
	ParticipantName     string `json:"participantName"`
	EnableTranscoding   bool   `json:"enableTranscoding"`
}

type createIngressAPIResponse struct {
	IngressID string `json:"ingressId"`
	URL       string `json:"url"`
}

type screenIngressResponse struct {
	IngressID string `json:"ingress_id"`
	RoomName  string `json:"room_name"`
	Identity  string `json:"participant_identity"`
	WHIPURL   string `json:"whip_url"`
}

func (h *ScreenIngressHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, `{"error":"Não autenticado"}`, http.StatusUnauthorized)
		return
	}

	var req createScreenIngressRequest
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<20)).Decode(&req); err != nil || strings.TrimSpace(req.ChannelID) == "" {
		http.Error(w, `{"error":"'channel_id' é obrigatório"}`, http.StatusBadRequest)
		return
	}

	channel, err := h.repo.GetChannelByID(req.ChannelID)
	if err != nil || channel == nil || string(channel.Type) != "voice" {
		http.Error(w, `{"error":"Canal de voz não encontrado"}`, http.StatusNotFound)
		return
	}
	isMember, err := h.repo.IsServerMember(channel.ServerID, userID)
	if err != nil || !isMember {
		http.Error(w, `{"error":"Acesso ao canal negado"}`, http.StatusForbidden)
		return
	}

	user, _ := h.repo.GetUserByID(userID)
	participantName := userID
	if user != nil && user.Username != "" {
		participantName = user.Username + " (tela)"
	}
	identity := userID + ":screen"

	apiToken, err := lkauth.NewAccessToken(h.cfg.LiveKitAPIKey, h.cfg.LiveKitSecret).
		AddGrant(&lkauth.VideoGrant{IngressAdmin: true}).
		SetValidFor(time.Minute).
		ToJWT()
	if err != nil {
		http.Error(w, `{"error":"Não foi possível autenticar com o LiveKit"}`, http.StatusInternalServerError)
		return
	}

	apiReq, err := json.Marshal(createIngressAPIRequest{
		InputType:           1, // WHIP_INPUT
		Name:                "screen-share-" + userID,
		RoomName:            channel.ID,
		ParticipantIdentity: identity,
		ParticipantName:     participantName,
		EnableTranscoding:   false,
	})
	if err != nil {
		http.Error(w, `{"error":"Não foi possível criar o Ingress"}`, http.StatusInternalServerError)
		return
	}

	apiURL := strings.TrimRight(h.cfg.LiveKitAPIURL, "/") + "/twirp/livekit.Ingress/CreateIngress"
	apiRequest, err := http.NewRequestWithContext(r.Context(), http.MethodPost, apiURL, bytes.NewReader(apiReq))
	if err != nil {
		http.Error(w, `{"error":"Configuração de API LiveKit inválida"}`, http.StatusInternalServerError)
		return
	}
	apiRequest.Header.Set("Authorization", "Bearer "+apiToken)
	apiRequest.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	apiResponse, err := client.Do(apiRequest)
	if err != nil {
		http.Error(w, `{"error":"LiveKit Ingress indisponível"}`, http.StatusBadGateway)
		return
	}
	defer apiResponse.Body.Close()
	if apiResponse.StatusCode != http.StatusOK {
		http.Error(w, `{"error":"LiveKit recusou a criação do Ingress"}`, http.StatusBadGateway)
		return
	}

	var ingress createIngressAPIResponse
	if err := json.NewDecoder(apiResponse.Body).Decode(&ingress); err != nil || ingress.URL == "" {
		http.Error(w, `{"error":"LiveKit retornou um Ingress inválido"}`, http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	_ = json.NewEncoder(w).Encode(screenIngressResponse{
		IngressID: ingress.IngressID,
		RoomName:  channel.ID,
		Identity:  identity,
		WHIPURL:   ingress.URL,
	})
}
