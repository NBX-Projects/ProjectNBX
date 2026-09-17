package screenshare

import (
	"time"

	"github.com/projectnbx/backend/internal/models"
)

// SessionState define o estado do compartilhamento de tela no canal
type SessionState string

const (
	SessionStateActive  SessionState = "ACTIVE"
	SessionStateStopped SessionState = "STOPPED"
)

// Constantes de erro do protocolo de Screen Sharing
const (
	ErrScreenShareAlreadyActive       = "SCREEN_SHARE_ALREADY_ACTIVE"
	ErrScreenShareNotActive          = "SCREEN_SHARE_NOT_ACTIVE"
	ErrScreenSharePermissionDenied   = "SCREEN_SHARE_PERMISSION_DENIED"
	ErrScreenShareViewerLimitReached = "SCREEN_SHARE_VIEWER_LIMIT_REACHED"
	ErrScreenShareSessionNotFound    = "SCREEN_SHARE_SESSION_NOT_FOUND"
	ErrScreenShareInvalidSession     = "SCREEN_SHARE_INVALID_SESSION"
	ErrScreenShareInvalidRecipient   = "SCREEN_SHARE_INVALID_RECIPIENT"
	ErrWebRTCSignalingUnauthorized   = "WEBRTC_SIGNALING_UNAUTHORIZED"
	ErrWebRTCSignalingInvalidPayload = "WEBRTC_SIGNALING_INVALID_PAYLOAD"
	ErrWebRTCSignalingRateLimited    = "WEBRTC_SIGNALING_RATE_LIMITED"
	ErrWebRTCSignalingOutOfOrder     = "WEBRTC_SIGNALING_OUT_OF_ORDER"
	ErrWebRTCSignalingInvalidState   = "WEBRTC_SIGNALING_INVALID_STATE"
)

// ChannelScreenShareState representa o estado autoritativo de uma transmissão no backend
type ChannelScreenShareState struct {
	SessionID     string              `json:"session_id"`
	ChannelID     string              `json:"channel_id"`
	BroadcasterID string              `json:"broadcaster_id"`
	State         SessionState        `json:"state"`
	Quality       string              `json:"quality,omitempty"`
	StartedAt     time.Time           `json:"started_at"`
	GraceUntil    *time.Time          `json:"grace_until,omitempty"`
	ViewerUserIDs map[string]struct{} `json:"viewer_user_ids"`
}

// ICECandidate estrutura de candidato ICE do WebRTC
type ICECandidate struct {
	Candidate     string  `json:"candidate"`
	SDPMid        *string `json:"sdpMid,omitempty"`
	SDPMLineIndex *int    `json:"sdpMLineIndex,omitempty"`
}

// WebRTCSignalingRequest DTO de entrada enviado pelo cliente (NUNCA possui from_user_id)
type WebRTCSignalingRequest struct {
	Type          models.EventType `json:"type"`
	ChannelID     string           `json:"channel_id"`
	SessionID     string           `json:"session_id,omitempty"`
	NegotiationID string           `json:"negotiation_id,omitempty"`
	Sequence      uint64           `json:"sequence,omitempty"`
	ToUserID      string           `json:"to_user_id,omitempty"`
	SDP           string           `json:"sdp,omitempty"`
	Candidate     *ICECandidate    `json:"candidate,omitempty"`
	Quality       string           `json:"quality,omitempty"` // "low", "medium", "high"
}

// WebRTCSignalingEvent DTO de saída repassado pelo servidor com remetente injetado
type WebRTCSignalingEvent struct {
	WebRTCSignalingRequest
	FromUserID string `json:"from_user_id"`
}

// Payloads de resposta e broadcast
type ScreenShareErrorPayload struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	SessionID string `json:"session_id,omitempty"`
	ChannelID string `json:"channel_id,omitempty"`
}

type ScreenShareStartedPayload struct {
	SessionID     string    `json:"session_id"`
	ChannelID     string    `json:"channel_id"`
	BroadcasterID string    `json:"broadcaster_id"`
	Quality       string    `json:"quality"`
	StartedAt     time.Time `json:"started_at"`
}

type ScreenShareAvailablePayload struct {
	SessionID     string    `json:"session_id"`
	ChannelID     string    `json:"channel_id"`
	BroadcasterID string    `json:"broadcaster_id"`
	Quality       string    `json:"quality"`
	StartedAt     time.Time `json:"started_at"`
}

type ScreenShareJoinedPayload struct {
	SessionID     string    `json:"session_id"`
	ChannelID     string    `json:"channel_id"`
	BroadcasterID string    `json:"broadcaster_id"`
	ViewerID      string    `json:"viewer_id"`
	Quality       string    `json:"quality"`
	StartedAt     time.Time `json:"started_at"`
}

type ScreenShareViewerJoinedPayload struct {
	SessionID string `json:"session_id"`
	ChannelID string `json:"channel_id"`
	ViewerID  string `json:"viewer_id"`
}

type ScreenShareViewerLeftPayload struct {
	SessionID string `json:"session_id"`
	ChannelID string `json:"channel_id"`
	ViewerID  string `json:"viewer_id"`
}

type ScreenShareStoppedPayload struct {
	SessionID     string `json:"session_id"`
	ChannelID     string `json:"channel_id"`
	BroadcasterID string `json:"broadcaster_id"`
}

// ScreenShareConfig define parâmetros de capacidade e segurança
type ScreenShareConfig struct {
	MaxViewers       int
	GracePeriod      time.Duration
	MaxSDPSize       int
	MaxCandidateSize int
}

func DefaultScreenShareConfig() ScreenShareConfig {
	return ScreenShareConfig{
		MaxViewers:       5,
		GracePeriod:      10 * time.Second,
		MaxSDPSize:       64 * 1024, // 64 KB
		MaxCandidateSize: 4 * 1024,  // 4 KB
	}
}

// TURNConfig define configurações para geração de credenciais temporárias TURN
type TURNConfig struct {
	Enabled       bool
	URLs          []string
	Secret        string
	CredentialTTL time.Duration
}

func DefaultTURNConfig() TURNConfig {
	return TURNConfig{
		Enabled:       false,
		URLs:          []string{},
		Secret:        "",
		CredentialTTL: 1 * time.Hour,
	}
}
