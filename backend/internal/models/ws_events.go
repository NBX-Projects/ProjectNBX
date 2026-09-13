package models

import "encoding/json"

// EventType define os tipos de eventos trafegados via WebSocket
type EventType string

const (
	EventChatMessage    EventType = "CHAT_MESSAGE"
	EventUserPresence   EventType = "USER_PRESENCE"
	EventVoiceState     EventType = "VOICE_STATE"
	EventChannelJoin    EventType = "CHANNEL_JOIN"
	EventChannelLeave   EventType = "CHANNEL_LEAVE"
	EventPing           EventType = "PING"
	EventPong           EventType = "PONG"
	EventError          EventType = "ERROR"
)

// WSEvent envelope padrão para mensagens WebSocket
type WSEvent struct {
	Type      EventType       `json:"type"`
	Payload   json.RawMessage `json:"payload"`
	ChannelID string          `json:"channel_id,omitempty"`
	ServerID  string          `json:"server_id,omitempty"`
}

// VoiceStatePayload informa se o usuário está mutado, ensurdecido ou falando
type VoiceStatePayload struct {
	UserID    string `json:"user_id"`
	ChannelID string `json:"channel_id"`
	IsMuted   bool   `json:"is_muted"`
	IsDeafened bool  `json:"is_deafened"`
	IsSpeaking bool  `json:"is_speaking"`
}

// PresencePayload informa o status de presença do usuário
type PresencePayload struct {
	UserID string `json:"user_id"`
	Status string `json:"status"` // "online", "idle", "dnd", "offline"
}
