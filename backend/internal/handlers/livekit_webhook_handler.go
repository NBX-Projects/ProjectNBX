package handlers

import (
	"log"
	"net/http"

	"github.com/livekit/protocol/auth"
	"github.com/livekit/protocol/livekit"
	"github.com/livekit/protocol/webhook"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/websocket"
)

type LiveKitKeyProvider struct {
	apiKey    string
	apiSecret string
}

func (p *LiveKitKeyProvider) GetSecret(key string) string {
	if key == p.apiKey {
		return p.apiSecret
	}
	return ""
}

func (p *LiveKitKeyProvider) NumKeys() int {
	return 1
}

type LiveKitWebhookHandler struct {
	keyProvider auth.KeyProvider
	repo        repository.Repository
	hub         *websocket.Hub
}

func NewLiveKitWebhookHandler(apiKey, apiSecret string, repo repository.Repository, hub *websocket.Hub) *LiveKitWebhookHandler {
	return &LiveKitWebhookHandler{
		keyProvider: &LiveKitKeyProvider{apiKey: apiKey, apiSecret: apiSecret},
		repo:        repo,
		hub:         hub,
	}
}

func (h *LiveKitWebhookHandler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
	event, err := webhook.ReceiveWebhookEvent(r, h.keyProvider)
	if err != nil {
		log.Printf("[LiveKit Webhook] Falha na validação de assinatura: %v", err)
		http.Error(w, "invalid signature", http.StatusUnauthorized)
		return
	}

	if event.Room == nil {
		w.WriteHeader(http.StatusOK)
		return
	}

	roomName := event.Room.Name
	channel, err := h.repo.GetChannelByID(roomName)
	if err != nil || channel == nil {
		log.Printf("[LiveKit Webhook] Canal não encontrado para a sala '%s'", roomName)
		w.WriteHeader(http.StatusOK)
		return
	}

	serverID := channel.ServerID
	channelID := channel.ID

	switch event.Event {
	case "room_started", webhook.EventParticipantJoined:
		if event.Participant != nil {
			log.Printf("[LiveKit Webhook] Participante entrou: %s (%s) no canal %s",
				event.Participant.Name, event.Participant.Identity, channelID)
			h.hub.SetLiveKitParticipantState(
				serverID,
				channelID,
				event.Participant.Identity,
				event.Participant.Name,
				true,
				false,
			)
		}

	case webhook.EventParticipantLeft:
		if event.Participant != nil {
			log.Printf("[LiveKit Webhook] Participante saiu: %s (%s) do canal %s",
				event.Participant.Name, event.Participant.Identity, channelID)
			h.hub.SetLiveKitParticipantState(
				serverID,
				channelID,
				event.Participant.Identity,
				event.Participant.Name,
				false,
				false,
			)
		}

	case webhook.EventRoomFinished:
		log.Printf("[LiveKit Webhook] Sala finalizada: canal %s", channelID)
		h.hub.ClearRoomVoiceStates(serverID, channelID)

	case webhook.EventTrackPublished:
		if event.Participant != nil && event.Track != nil {
			isTransmitting := event.Track.Source == livekit.TrackSource_SCREEN_SHARE
			if isTransmitting {
				h.hub.UpdateParticipantTransmitting(serverID, channelID, event.Participant.Identity, true)
			}
		}

	case webhook.EventTrackUnpublished:
		if event.Participant != nil && event.Track != nil {
			if event.Track.Source == livekit.TrackSource_SCREEN_SHARE {
				h.hub.UpdateParticipantTransmitting(serverID, channelID, event.Participant.Identity, false)
			}
		}
	}

	w.WriteHeader(http.StatusOK)
}
