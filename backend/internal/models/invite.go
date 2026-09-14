package models

import "time"

// ServerInvite representa um convite temporário ou permanente para um servidor
type ServerInvite struct {
	Code       string     `json:"code"`
	ServerID   string     `json:"server_id"`
	CreatorID  string     `json:"creator_id"`
	Creator    *User      `json:"creator,omitempty"`
	MaxUses    int        `json:"max_uses"`    // 0 = ilimitado
	UsesCount  int        `json:"uses_count"`  // total de vezes usado
	ExpiresAt  *time.Time `json:"expires_at"`  // nil = nunca expira
	CreatedAt  time.Time  `json:"created_at"`
	IsExpired  bool       `json:"is_expired"`
	IsExhausted bool      `json:"is_exhausted"`
}

// CreateInviteRequest payload para gerar um novo convite
type CreateInviteRequest struct {
	MaxAgeSeconds *int `json:"max_age_seconds,omitempty"` // Segundos até expirar (ex: 86400 para 24h, 0/nil para nunca)
	MaxUses       *int `json:"max_uses,omitempty"`        // 0 ou nil = sem limite
}

// JoinServerResponse resposta ao ingressar com código de convite
type JoinServerResponse struct {
	Server  *Server       `json:"server"`
	Member  *ServerMember `json:"member"`
	Message string        `json:"message"`
}

