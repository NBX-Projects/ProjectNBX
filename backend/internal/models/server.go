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
	IsPublic    bool       `json:"is_public"`
	Description string     `json:"description,omitempty"`
	Category    string     `json:"category,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
}

// CreateServerRequest payload para criar um novo servidor
type CreateServerRequest struct {
	Name        string `json:"name"`
	IconURL     string `json:"icon_url,omitempty"`
	IsPublic    bool   `json:"is_public"`
	Description string `json:"description,omitempty"`
	Category    string `json:"category,omitempty"`
}

// CreateChannelRequest payload para criar um canal
type CreateChannelRequest struct {
	Name string      `json:"name"`
	Type ChannelType `json:"type"`
}

// ServerMember representa a associação entre um usuário e um servidor
type ServerMember struct {
	ServerID string        `json:"server_id"`
	UserID   string        `json:"user_id"`
	User     *User         `json:"user,omitempty"`
	Role     string        `json:"role"` // "owner", "member"
	Roles    []*ServerRole `json:"roles,omitempty"`
	JoinedAt time.Time     `json:"joined_at"`
}

// AddMemberRequest payload para adicionar um membro a um servidor
type AddMemberRequest struct {
	UserID   string `json:"user_id,omitempty"`
	Username string `json:"username,omitempty"`
	Email    string `json:"email,omitempty"`
}

// ServerRole define um cargo personalizado dentro do servidor
type ServerRole struct {
	ID          string          `json:"id"`
	ServerID    string          `json:"server_id"`
	Name        string          `json:"name"`
	Color       int64           `json:"color"`
	Position    int             `json:"position"`
	Permissions map[string]bool `json:"permissions"`
	CreatedAt   time.Time       `json:"created_at"`
}

// CreateRoleRequest payload para criar/editar um cargo
type CreateRoleRequest struct {
	Name        string          `json:"name"`
	Color       int64           `json:"color"`
	Position    int             `json:"position"`
	Permissions map[string]bool `json:"permissions"`
}

// ServerJoinRequest define uma solicitação de entrada em servidor público
type ServerJoinRequest struct {
	ID         string     `json:"id"`
	ServerID   string     `json:"server_id"`
	UserID     string     `json:"user_id"`
	User       *User      `json:"user,omitempty"`
	Message    string     `json:"message,omitempty"`
	Status     string     `json:"status"` // "pending", "approved", "rejected"
	CreatedAt  time.Time  `json:"created_at"`
	ReviewedBy *string    `json:"reviewed_by,omitempty"`
	ReviewedAt *time.Time `json:"reviewed_at,omitempty"`
}

// PublicServerDTO representa o servidor público com status de solicitação do usuário autenticado
type PublicServerDTO struct {
	Server
	IsMember          bool   `json:"is_member"`
	JoinRequestStatus string `json:"join_request_status"` // "none", "pending", "approved", "rejected"
}

