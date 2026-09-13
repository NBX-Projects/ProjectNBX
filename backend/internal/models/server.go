package models

import "time"

// ChannelType define o tipo do canal (texto ou voz)
type ChannelType string

const (
	ChannelTypeText  ChannelType = "text"
	ChannelTypeVoice ChannelType = "voice"
)

// Channel representa um canal de texto ou voz dentro de um servidor
type Channel struct {
	ID        string      `json:"id"`
	ServerID  string      `json:"server_id"`
	Name      string      `json:"name"`
	Type      ChannelType `json:"type"`
	Position  int         `json:"position"`
	CreatedAt time.Time   `json:"created_at"`
}

// Server representa uma guilda/servidor comunitário
type Server struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	IconURL     string     `json:"icon_url,omitempty"`
	OwnerID     string     `json:"owner_id"`
	Channels    []*Channel `json:"channels,omitempty"`
	MemberCount int        `json:"member_count"`
	CreatedAt   time.Time  `json:"created_at"`
}

// CreateServerRequest payload para criar um novo servidor
type CreateServerRequest struct {
	Name    string `json:"name"`
	IconURL string `json:"icon_url,omitempty"`
}

// CreateChannelRequest payload para criar um canal
type CreateChannelRequest struct {
	Name string      `json:"name"`
	Type ChannelType `json:"type"`
}
