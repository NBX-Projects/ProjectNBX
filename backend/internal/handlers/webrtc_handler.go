package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/screenshare"
)

type WebRTCHandler struct {
	turnService *screenshare.TURNService
}

func NewWebRTCHandler(turnService *screenshare.TURNService) *WebRTCHandler {
	return &WebRTCHandler{
		turnService: turnService,
	}
}

// GetTURNCredentials retorna credenciais efêmeras HMAC-SHA1 RFC 5766 para o usuário autenticado
func (h *WebRTCHandler) GetTURNCredentials(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, `{"error":"Não autenticado"}`, http.StatusUnauthorized)
		return
	}

	creds, err := h.turnService.GenerateCredentials(userID)
	if err != nil {
		http.Error(w, `{"error":"Erro ao gerar credenciais TURN"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	_ = json.NewEncoder(w).Encode(creds)
}
