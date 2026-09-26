package models

import "time"

// Message representa uma mensagem enviada em um canal de texto
type Message struct {
	ID        string    `json:"id"`
	ChannelID string    `json:"channel_id"`
	ServerID  string    `json:"server_id"`
	AuthorID  string    `json:"author_id"`
	Author    *User     `json:"author,omitempty"`
	Content   string    `json:"content"`
	MediaURL  string    `json:"media_url,omitempty"`
	MediaType string    `json:"media_type,omitempty"`
	IsEdited  bool      `json:"is_edited,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at,omitempty"`
}

// UpdateMessageRequest payload para edição de mensagem REST
type UpdateMessageRequest struct {
	Content string `json:"content"`
}
