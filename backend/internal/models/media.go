package models

import "time"

// MediaUpload registra a propriedade de um arquivo de mídia enviado ao storage
type MediaUpload struct {
	URL       string    `json:"url"`
	OwnerID   string    `json:"owner_id"`
	MediaType string    `json:"media_type"`
	SizeBytes int64     `json:"size_bytes"`
	CreatedAt time.Time `json:"created_at"`
}
