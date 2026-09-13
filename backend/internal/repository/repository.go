package repository

import (
	"errors"

	"github.com/projectnbx/backend/internal/models"
)

var (
	ErrNotFound      = errors.New("recurso não encontrado")
	ErrAlreadyExists = errors.New("recurso já cadastrado")
	ErrUnauthorized  = errors.New("não autorizado")
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
	ListMessagesByChannel(channelID string, limit int) ([]*models.Message, error)
}
