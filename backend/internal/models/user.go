package models

import "time"

// User representa um usuário no sistema
type User struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"` // Nome completo / Display Name
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	Password  string    `json:"-"` // Ocultado na serialização JSON
	AvatarURL    string    `json:"avatar_url,omitempty"`
	BannerURL    string    `json:"banner_url,omitempty"`
	Bio          string    `json:"bio,omitempty"`
	CustomStatus string    `json:"custom_status,omitempty"`
	Status       string    `json:"status"` // "online", "idle", "dnd", "offline"
	CreatedAt    time.Time `json:"created_at"`
}

// RegisterRequest payload de registro de usuário
type RegisterRequest struct {
	Name     string `json:"name"`
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

// LoginRequest payload de login (suporta login por username ou email)
type LoginRequest struct {
	Login    string `json:"login"` // Username ou E-mail
	Email    string `json:"email"` // Fallback de compatibilidade
	Password string `json:"password"`
}

// UpdateUserRequest payload para atualização cadastral e perfil do usuário
type UpdateUserRequest struct {
	Name         string  `json:"name"`
	Username     string  `json:"username"`
	Email        string  `json:"email"`
	AvatarURL    *string `json:"avatar_url,omitempty"`
	BannerURL    *string `json:"banner_url,omitempty"`
	Bio          *string `json:"bio,omitempty"`
	CustomStatus *string `json:"custom_status,omitempty"`
	Status       *string `json:"status,omitempty"`
}

// ChangePasswordRequest payload para alteração de senha
type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

// AuthResponse resposta de autenticação com JWT e dados do usuário
type AuthResponse struct {
	Token string `json:"token"`
	User  *User  `json:"user"`
}

