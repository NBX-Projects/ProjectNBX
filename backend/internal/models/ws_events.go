package models

import "encoding/json"

// EventType define os tipos de eventos trafegados via WebSocket
type EventType string

const (
	EventChatMessage    EventType = "CHAT_MESSAGE"
	EventMessageUpdate  EventType = "MESSAGE_UPDATE"
	EventMessageDelete  EventType = "MESSAGE_DELETE"
	EventUserPresence   EventType = "USER_PRESENCE"
	EventVoiceState     EventType = "VOICE_STATE"
	EventVoiceSync      EventType = "VOICE_SYNC"
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

// VoiceParticipantState representa o estado em tempo real de um participante no canal de voz
type VoiceParticipantState struct {
	SessionID      string `json:"session_id"`
	UserID         string `json:"user_id"`
	Username       string `json:"username"`
	ServerID       string `json:"server_id"`
	ChannelID      string `json:"channel_id"`
	Device         string `json:"device,omitempty"` // "desktop", "mobile", "web"
	IsInVoice      bool   `json:"is_in_voice"`
	IsConnecting   bool   `json:"is_connecting,omitempty"`
	IsTransmitting bool   `json:"is_transmitting"`
	StreamTitle    string `json:"stream_title,omitempty"`
	PreviewType    string `json:"preview_type,omitempty"`
	Thumbnail      string `json:"thumbnail,omitempty"`
	IsMuted        bool   `json:"is_muted"`
	IsDeafened     bool   `json:"is_deafened"`
	IsSpeaking     bool   `json:"is_speaking"`
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
