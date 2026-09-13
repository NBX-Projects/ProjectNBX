package models

import "time"

// User representa um usuário no sistema
type User struct {
	ID        string    `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	Password  string    `json:"-"` // Ocultado na serialização JSON
	AvatarURL string    `json:"avatar_url,omitempty"`
	Status    string    `json:"status"` // "online", "idle", "dnd", "offline"
	CreatedAt time.Time `json:"created_at"`
}

// RegisterRequest payload de registro de usuário
type RegisterRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

// LoginRequest payload de login
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// AuthResponse resposta de autenticação com JWT e dados do usuário
type AuthResponse struct {
	Token string `json:"token"`
	User  *User  `json:"user"`
}
