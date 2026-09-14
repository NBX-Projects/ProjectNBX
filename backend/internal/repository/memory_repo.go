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
	members  map[string]map[string]time.Time // serverID -> userID -> joinedAt
	invites  map[string]*models.ServerInvite // code -> invite
}

// NewMemoryRepository inicializa o repositório com dados padrão de demonstração
func NewMemoryRepository() *MemoryRepository {
	repo := &MemoryRepository{
		users:    make(map[string]*models.User),
		servers:  make(map[string]*models.Server),
		channels: make(map[string]*models.Channel),
		messages: make(map[string][]*models.Message),
		members:  make(map[string]map[string]time.Time),
		invites:  make(map[string]*models.ServerInvite),
	}

	repo.seedInitialData()
	return repo
}

func (r *MemoryRepository) seedInitialData() {
	// Criação de usuário admin/dev padrão (senha: admin123)
	hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	adminUser := &models.User{
		ID:        "usr_dev_1",
		Username:  "DarkLord_X",
		Email:     "dev@projectnbx.com",
		Password:  string(hash),
		AvatarURL: "https://api.dicebear.com/7.x/bottts/svg?seed=nbxdev",
		Status:    "online",
		CreatedAt: time.Now(),
	}
	r.users[adminUser.ID] = adminUser

	// Usuário demo dev@nbx.com (senha: senha_segura_123)
	devHash, _ := bcrypt.GenerateFromPassword([]byte("senha_segura_123"), bcrypt.DefaultCost)
	devUser := &models.User{
		ID:        "usr_dev_2",
		Username:  "DevNBX",
		Email:     "dev@nbx.com",
		Password:  string(devHash),
		AvatarURL: "https://api.dicebear.com/7.x/bottts/svg?seed=taui",
		Status:    "online",
		CreatedAt: time.Now(),
	}
	r.users[devUser.ID] = devUser

	seedServers := []struct {
		ID       string
		Name     string
		Banner   string
		Channels []struct {
			ID   string
			Name string
			Type models.ChannelType
		}
	}{
		{
			ID:     "1",
			Name:   "Apex Predators",
			Banner: "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type models.ChannelType
			}{
				{"t1", "geral", models.ChannelTypeText},
				{"t2", "anúncios", models.ChannelTypeText},
				{"v1", "Ranked Match", models.ChannelTypeVoice},
			},
		},
		{
			ID:     "2",
			Name:   "Dev Lounge",
			Banner: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type models.ChannelType
			}{
				{"t3", "geral", models.ChannelTypeText},
				{"v2", "Code Review", models.ChannelTypeVoice},
			},
		},
		{
			ID:     "3",
			Name:   "Le Mans Ultimate",
			Banner: "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type models.ChannelType
			}{
				{"t4", "geral", models.ChannelTypeText},
				{"v3", "Live Stream", models.ChannelTypeVoice},
			},
		},
		{
			ID:     "4",
			Name:   "Minecraft Realm",
			Banner: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type models.ChannelType
			}{
				{"t5", "geral", models.ChannelTypeText},
				{"v4", "Build Session", models.ChannelTypeVoice},
			},
		},
		{
			ID:     "5",
			Name:   "CS2 Tactics",
			Banner: "https://images.unsplash.com/photo-1547394765-185e1e68f34e?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type models.ChannelType
			}{
				{"t6", "geral", models.ChannelTypeText},
				{"v5", "Scrim Room", models.ChannelTypeVoice},
			},
		},
		{
			ID:     "6",
			Name:   "Study Group",
			Banner: "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1400&h=420&fit=crop&auto=format",
			Channels: []struct {
				ID   string
				Name string
				Type models.ChannelType
			}{
				{"t7", "geral", models.ChannelTypeText},
				{"v6", "Foco Total", models.ChannelTypeVoice},
			},
		},
	}

	for _, sData := range seedServers {
		srv := &models.Server{
			ID:          sData.ID,
			Name:        sData.Name,
			IconURL:     sData.Banner,
			OwnerID:     adminUser.ID,
			MemberCount: 100,
			CreatedAt:   time.Now(),
		}
		r.servers[srv.ID] = srv

		for pos, cData := range sData.Channels {
			ch := &models.Channel{
				ID:        cData.ID,
				ServerID:  srv.ID,
				Name:      cData.Name,
				Type:      cData.Type,
				Position:  pos + 1,
				CreatedAt: time.Now(),
			}
			r.channels[ch.ID] = ch
		}
	}

	// Mensagem de boas vindas no canal t1
	welcomeMsg := &models.Message{
		ID:        uuid.New().String(),
		ChannelID: "t1",
		ServerID:  "1",
		AuthorID:  adminUser.ID,
		Author:    adminUser,
		Content:   "Pessoal, campeonato interno começa sábado às 21h 🏆",
		CreatedAt: time.Now(),
	}
	r.messages["t1"] = []*models.Message{welcomeMsg}
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

func (r *MemoryRepository) GetMessageByID(id string) (*models.Message, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, msgs := range r.messages {
		for _, m := range msgs {
			if m.ID == id {
				return m, nil
			}
		}
	}
	return nil, ErrNotFound
}

func (r *MemoryRepository) UpdateMessage(id, content string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, msgs := range r.messages {
		for _, m := range msgs {
			if m.ID == id {
				m.Content = content
				m.IsEdited = true
				m.UpdatedAt = time.Now()
				return nil
			}
		}
	}
	return ErrNotFound
}

func (r *MemoryRepository) DeleteMessage(id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for channelID, msgs := range r.messages {
		for i, m := range msgs {
			if m.ID == id {
				r.messages[channelID] = append(msgs[:i], msgs[i+1:]...)
				return nil
			}
		}
	}
	return ErrNotFound
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

func (r *MemoryRepository) CreateAuditLog(log *models.AuditLog) error {
	return nil
}

func (r *MemoryRepository) ListAuditLogs(limit int, source models.AuditSource) ([]*models.AuditLog, error) {
	return []*models.AuditLog{}, nil
}

func (r *MemoryRepository) AddServerMember(serverID, userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, ok := r.members[serverID]; !ok {
		r.members[serverID] = make(map[string]time.Time)
	}
	r.members[serverID][userID] = time.Now()

	if srv, ok := r.servers[serverID]; ok {
		srv.MemberCount = len(r.members[serverID])
	}
	return nil
}

func (r *MemoryRepository) RemoveServerMember(serverID, userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if m, ok := r.members[serverID]; ok {
		delete(m, userID)
		if srv, ok := r.servers[serverID]; ok {
			srv.MemberCount = len(m)
		}
	}
	return nil
}

func (r *MemoryRepository) ListServerMembers(serverID string) ([]*models.ServerMember, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	srv, ok := r.servers[serverID]
	if !ok {
		return nil, ErrNotFound
	}

	membersMap, ok := r.members[serverID]
	if !ok {
		// If empty, return owner as member
		if owner, ok := r.users[srv.OwnerID]; ok {
			return []*models.ServerMember{
				{
					ServerID: serverID,
					UserID:   owner.ID,
					User:     owner,
					Role:     "owner",
					JoinedAt: srv.CreatedAt,
				},
			}, nil
		}
		return []*models.ServerMember{}, nil
	}

	result := make([]*models.ServerMember, 0, len(membersMap))
	for uid, joinedAt := range membersMap {
		u, ok := r.users[uid]
		if !ok {
			continue
		}
		role := "member"
		if uid == srv.OwnerID {
			role = "owner"
		}
		result = append(result, &models.ServerMember{
			ServerID: serverID,
			UserID:   uid,
			User:     u,
			Role:     role,
			JoinedAt: joinedAt,
		})
	}
	return result, nil
}

func (r *MemoryRepository) IsServerMember(serverID, userID string) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	srv, ok := r.servers[serverID]
	if !ok {
		return false, ErrNotFound
	}

	if srv.OwnerID == userID {
		return true, nil
	}

	if membersMap, ok := r.members[serverID]; ok {
		if _, exists := membersMap[userID]; exists {
			return true, nil
		}
	}
	return false, nil
}

func (r *MemoryRepository) FindUser(query string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, u := range r.users {
		if u.ID == query || u.Email == query || u.Username == query {
			return u, nil
		}
	}
	return nil, ErrNotFound
}

func (r *MemoryRepository) SearchUsers(query string, limit int) ([]*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if limit <= 0 {
		limit = 10
	}
	var res []*models.User
	for _, u := range r.users {
		if len(res) >= limit {
			break
		}
		res = append(res, u)
	}
	return res, nil
}

// Invite Methods
func (r *MemoryRepository) CreateInvite(invite *models.ServerInvite) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if invite.CreatedAt.IsZero() {
		invite.CreatedAt = time.Now()
	}
	r.invites[invite.Code] = invite
	return nil
}

func (r *MemoryRepository) GetInviteByCode(code string) (*models.ServerInvite, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	invite, ok := r.invites[code]
	if !ok {
		return nil, ErrNotFound
	}

	invCopy := *invite
	if invCopy.Creator == nil {
		if creator, exists := r.users[invCopy.CreatorID]; exists {
			invCopy.Creator = creator
		}
	}

	now := time.Now()
	if invCopy.ExpiresAt != nil && now.After(*invCopy.ExpiresAt) {
		invCopy.IsExpired = true
	}
	if invCopy.MaxUses > 0 && invCopy.UsesCount >= invCopy.MaxUses {
		invCopy.IsExhausted = true
	}

	return &invCopy, nil
}

func (r *MemoryRepository) IncrementInviteUses(code string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	invite, ok := r.invites[code]
	if !ok {
		return ErrNotFound
	}
	if invite.MaxUses > 0 && invite.UsesCount >= invite.MaxUses {
		return ErrMaxUsesReached
	}
	invite.UsesCount++
	return nil
}

func (r *MemoryRepository) ListServerInvites(serverID string) ([]*models.ServerInvite, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	res := make([]*models.ServerInvite, 0)
	now := time.Now()

	for _, inv := range r.invites {
		if inv.ServerID == serverID {
			invCopy := *inv
			if invCopy.Creator == nil {
				if creator, exists := r.users[invCopy.CreatorID]; exists {
					invCopy.Creator = creator
				}
			}
			if invCopy.ExpiresAt != nil && now.After(*invCopy.ExpiresAt) {
				invCopy.IsExpired = true
			}
			if invCopy.MaxUses > 0 && invCopy.UsesCount >= invCopy.MaxUses {
				invCopy.IsExhausted = true
			}
			res = append(res, &invCopy)
		}
	}
	return res, nil
}

func (r *MemoryRepository) DeleteInvite(code string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.invites, code)
	return nil
}
