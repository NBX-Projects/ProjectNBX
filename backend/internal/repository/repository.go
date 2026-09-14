package repository

import (
	"errors"

	"github.com/projectnbx/backend/internal/models"
)

var (
	ErrNotFound         = errors.New("recurso não encontrado")
	ErrAlreadyExists    = errors.New("recurso já cadastrado")
	ErrUnauthorized     = errors.New("não autorizado")
	ErrExpired          = errors.New("código de convite expirado")
	ErrMaxUsesReached   = errors.New("este convite já atingiu o limite máximo de utilizações")
)

// Repository interface para operações de banco de dados
type Repository interface {
	// Usuários
	CreateUser(user *models.User) error
	GetUserByID(id string) (*models.User, error)
	GetUserByEmail(email string) (*models.User, error)
	UpdateUserStatus(id, status string) error

	// Servidores
	CreateServer(server *models.Server) error
	GetServerByID(id string) (*models.Server, error)
	ListServers() ([]*models.Server, error)

	// Canais
	CreateChannel(channel *models.Channel) error
	GetChannelByID(id string) (*models.Channel, error)
	ListChannelsByServer(serverID string) ([]*models.Channel, error)

	// Mensagens
	CreateMessage(msg *models.Message) error
	GetMessageByID(id string) (*models.Message, error)
	UpdateMessage(id, content string) error
	DeleteMessage(id string) error
	ListMessagesByChannel(channelID string, limit int) ([]*models.Message, error)

	// Auditoria
	CreateAuditLog(log *models.AuditLog) error
	ListAuditLogs(limit int, source models.AuditSource) ([]*models.AuditLog, error)

	// Membros do Servidor & Busca de Usuários
	AddServerMember(serverID, userID string) error
	RemoveServerMember(serverID, userID string) error
	ListServerMembers(serverID string) ([]*models.ServerMember, error)
	IsServerMember(serverID, userID string) (bool, error)
	FindUser(query string) (*models.User, error)
	SearchUsers(query string, limit int) ([]*models.User, error)

	// Convites do Servidor (Short & Temporary)
	CreateInvite(invite *models.ServerInvite) error
	GetInviteByCode(code string) (*models.ServerInvite, error)
	IncrementInviteUses(code string) error
	ListServerInvites(serverID string) ([]*models.ServerInvite, error)
	DeleteInvite(code string) error
}
