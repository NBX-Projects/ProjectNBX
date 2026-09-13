package models

import (
	"time"
)

type AuditSource string

const (
	AuditSourceAuth    AuditSource = "AUTH"
	AuditSourceServer  AuditSource = "SERVER"
	AuditSourceChannel AuditSource = "CHANNEL"
	AuditSourceChat    AuditSource = "CHAT"
	AuditSourceVoice   AuditSource = "VOICE"
	AuditSourceUser    AuditSource = "USER"
	AuditSourceSystem  AuditSource = "SYSTEM"
	AuditSourceAdmin   AuditSource = "ADMIN"
)

type AuditLog struct {
	ID         string                 `json:"id"`
	Source     AuditSource            `json:"source"`
	Action     string                 `json:"action"`
	UserID     *string                `json:"user_id,omitempty"`
	ResourceID *string                `json:"resource_id,omitempty"`
	IPAddress  string                 `json:"ip_address,omitempty"`
	UserAgent  string                 `json:"user_agent,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt  time.Time              `json:"created_at"`
}
