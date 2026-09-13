package repository

import (
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/projectnbx/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
)

// MemoryRepository implementação em memória thread-safe para desenvolvimento ágil
type MemoryRepository struct {
	mu       sync.RWMutex
	users    map[string]*models.User
	servers  map[string]*models.Server
	channels map[string]*models.Channel
	messages map[string][]*models.Message // channelID -> messages
}

// NewMemoryRepository inicializa o repositório com dados padrão de demonstração
func NewMemoryRepository() *MemoryRepository {
	repo := &MemoryRepository{
		users:    make(map[string]*models.User),
		servers:  make(map[string]*models.Server),
		channels: make(map[string]*models.Channel),
		messages: make(map[string][]*models.Message),
	}

	repo.seedInitialData()
	return repo
}

func (r *MemoryRepository) seedInitialData() {
	// Criação de usuário admin/dev padrão (senha: admin123)
	hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	adminUser := &models.User{
		ID:        "usr_dev_1",
		Username:  "NBX_Dev",
		Email:     "dev@projectnbx.com",
		Password:  string(hash),
		AvatarURL: "https://api.dicebear.com/7.x/bottts/svg?seed=nbxdev",
		Status:    "online",
		CreatedAt: time.Now(),
	}
	r.users[adminUser.ID] = adminUser

	// Servidor padrão de Comunidade NBX
	serverID := "srv_main_nbx"
	server := &models.Server{
		ID:          serverID,
		Name:        "ProjectNBX Lounge",
		IconURL:     "https://api.dicebear.com/7.x/identicon/svg?seed=ProjectNBX",
		OwnerID:     adminUser.ID,
		MemberCount: 42,
		CreatedAt:   time.Now(),
	}
	r.servers[serverID] = server

	// Canais padrão
	c1 := &models.Channel{
		ID:        "chn_general_chat",
		ServerID:  serverID,
		Name:      "geral-devs",
		Type:      models.ChannelTypeText,
		Position:  1,
		CreatedAt: time.Now(),
	}
	c2 := &models.Channel{
		ID:        "chn_voice_lounge",
		ServerID:  serverID,
		Name:      "Sala de Voz Principal",
		Type:      models.ChannelTypeVoice,
		Position:  2,
		CreatedAt: time.Now(),
	}
	c3 := &models.Channel{
		ID:        "chn_voice_gaming",
		ServerID:  serverID,
		Name:      "Gaming & Chill",
		Type:      models.ChannelTypeVoice,
		Position:  3,
		CreatedAt: time.Now(),
	}

	r.channels[c1.ID] = c1
	r.channels[c2.ID] = c2
	r.channels[c3.ID] = c3

	// Mensagem de boas vindas
	welcomeMsg := &models.Message{
		ID:        uuid.New().String(),
		ChannelID: c1.ID,
		ServerID:  serverID,
		AuthorID:  adminUser.ID,
		Author:    adminUser,
		Content:   "🚀 Bem-vindo ao servidor oficial do ProjectNBX! Voz WebRTC de ultrabaixa latência conectada via LiveKit.",
		CreatedAt: time.Now(),
	}
	r.messages[c1.ID] = []*models.Message{welcomeMsg}
}

// User methods
func (r *MemoryRepository) CreateUser(user *models.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, u := range r.users {
		if u.Email == user.Email {
			return ErrAlreadyExists
		}
	}

	if user.ID == "" {
		user.ID = "usr_" + uuid.New().String()
	}
	user.CreatedAt = time.Now()
	r.users[user.ID] = user
	return nil
}

func (r *MemoryRepository) GetUserByID(id string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	user, ok := r.users[id]
	if !ok {
		return nil, ErrNotFound
	}
	return user, nil
}

func (r *MemoryRepository) GetUserByEmail(email string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, u := range r.users {
		if u.Email == email {
			return u, nil
		}
	}
	return nil, ErrNotFound
}

func (r *MemoryRepository) UpdateUserStatus(id, status string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	user, ok := r.users[id]
	if !ok {
		return ErrNotFound
	}
	user.Status = status
	return nil
}

// Server methods
func (r *MemoryRepository) CreateServer(server *models.Server) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if server.ID == "" {
		server.ID = "srv_" + uuid.New().String()
	}
	server.CreatedAt = time.Now()
	server.MemberCount = 1
	r.servers[server.ID] = server
	return nil
}

func (r *MemoryRepository) GetServerByID(id string) (*models.Server, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	server, ok := r.servers[id]
	if !ok {
		return nil, ErrNotFound
	}
	return server, nil
}

func (r *MemoryRepository) ListServers() ([]*models.Server, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	servers := make([]*models.Server, 0, len(r.servers))
	for _, s := range r.servers {
		// Carrega canais vinculados
		channels := make([]*models.Channel, 0)
		for _, c := range r.channels {
			if c.ServerID == s.ID {
				channels = append(channels, c)
			}
		}
		sCopy := *s
		sCopy.Channels = channels
		servers = append(servers, &sCopy)
	}
	return servers, nil
}

// Channel methods
func (r *MemoryRepository) CreateChannel(channel *models.Channel) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if channel.ID == "" {
		channel.ID = "chn_" + uuid.New().String()
	}
	channel.CreatedAt = time.Now()
	r.channels[channel.ID] = channel
	return nil
}

func (r *MemoryRepository) GetChannelByID(id string) (*models.Channel, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	channel, ok := r.channels[id]
	if !ok {
		return nil, ErrNotFound
	}
	return channel, nil
}

func (r *MemoryRepository) ListChannelsByServer(serverID string) ([]*models.Channel, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	channels := make([]*models.Channel, 0)
	for _, c := range r.channels {
		if c.ServerID == serverID {
			channels = append(channels, c)
		}
	}
	return channels, nil
}

// Message methods
func (r *MemoryRepository) CreateMessage(msg *models.Message) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if msg.ID == "" {
		msg.ID = "msg_" + uuid.New().String()
	}
	msg.CreatedAt = time.Now()
	r.messages[msg.ChannelID] = append(r.messages[msg.ChannelID], msg)
	return nil
}

func (r *MemoryRepository) ListMessagesByChannel(channelID string, limit int) ([]*models.Message, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	msgs, ok := r.messages[channelID]
	if !ok {
		return []*models.Message{}, nil
	}

	if limit <= 0 || limit > len(msgs) {
		limit = len(msgs)
	}
	start := len(msgs) - limit
	return msgs[start:], nil
}
