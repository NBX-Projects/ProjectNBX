package repository

import (
	"context"
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
	// Diagnóstico & Conectividade
	Ping(ctx context.Context) error

	// Usuários
	CreateUser(user *models.User) error
	GetUserByID(id string) (*models.User, error)
	GetUserByEmail(email string) (*models.User, error)
	GetUserByEmailOrUsername(identifier string) (*models.User, error)
	UpdateUser(user *models.User) error
	UpdateUserPassword(id, hashedPassword string) error
	UpdateUserStatus(id, status string) error

	// Servidores
	CreateServer(server *models.Server) error
	GetServerByID(id string) (*models.Server, error)
	ListServers() ([]*models.Server, error)
	UpdateServer(server *models.Server) error

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

	// Servidores Públicos & Descoberta
	ListPublicServers(userID string) ([]*models.PublicServerDTO, error)

	// Solicitações de Entrada (Join Requests)
	CreateJoinRequest(req *models.ServerJoinRequest) error
	GetJoinRequest(serverID, userID string) (*models.ServerJoinRequest, error)
	ListJoinRequests(serverID string, status string) ([]*models.ServerJoinRequest, error)
	ReviewJoinRequest(requestID, reviewerID, status string) error

	// Cargos do Servidor (Roles)
	CreateRole(role *models.ServerRole) error
	GetRoleByID(id string) (*models.ServerRole, error)
	UpdateRole(role *models.ServerRole) error
	DeleteRole(roleID string) error
	ListServerRoles(serverID string) ([]*models.ServerRole, error)
	AssignMemberRole(serverID, userID, roleID string) error
	RemoveMemberRole(serverID, userID, roleID string) error
	GetMemberRoles(serverID, userID string) ([]*models.ServerRole, error)
	HasServerPermission(serverID, userID, permission string) (bool, error)
}

