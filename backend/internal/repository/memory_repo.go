package repository

import (
	"context"
	"errors"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/projectnbx/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
)

// MemoryRepository implementação em memória thread-safe para desenvolvimento ágil
type MemoryRepository struct {
	mu           sync.RWMutex
	users        map[string]*models.User
	servers      map[string]*models.Server
	channels     map[string]*models.Channel
	messages     map[string][]*models.Message // channelID -> messages
	members      map[string]map[string]time.Time // serverID -> userID -> joinedAt
	invites      map[string]*models.ServerInvite // code -> invite
	joinRequests map[string]*models.ServerJoinRequest // requestID -> joinRequest
	roles        map[string]*models.ServerRole // roleID -> role
	memberRoles  map[string]map[string][]string // serverID -> userID -> []roleID
}

// NewMemoryRepository inicializa o repositório com dados padrão de demonstração
func NewMemoryRepository() *MemoryRepository {
	repo := &MemoryRepository{
		users:        make(map[string]*models.User),
		servers:      make(map[string]*models.Server),
		channels:     make(map[string]*models.Channel),
		messages:     make(map[string][]*models.Message),
		members:      make(map[string]map[string]time.Time),
		invites:      make(map[string]*models.ServerInvite),
		joinRequests: make(map[string]*models.ServerJoinRequest),
		roles:        make(map[string]*models.ServerRole),
		memberRoles:  make(map[string]map[string][]string),
	}

	repo.seedInitialData()
	return repo
}

func (r *MemoryRepository) seedInitialData() {
	// Criação de usuário admin/dev padrão (senha: admin123)
	hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	adminUser := &models.User{
		ID:        "usr_dev_1",
		Name:      "DarkLord X",
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
		Name:      "Dev NBX",
		Username:  "DevNBX",
		Email:     "dev@nbx.com",
		Password:  string(devHash),
		AvatarURL: "https://api.dicebear.com/7.x/bottts/svg?seed=taui",
		Status:    "online",
		CreatedAt: time.Now(),
	}
	r.users[devUser.ID] = devUser

	seedServers := []struct {
		ID          string
		Name        string
		Banner      string
		IsPublic    bool
		Category    string
		Description string
		Channels    []struct {
			ID   string
			Name string
			Type models.ChannelType
		}
	}{
		{
			ID:          "1",
			Name:        "Apex Predators",
			Banner:      "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=1400&h=420&fit=crop&auto=format",
			IsPublic:    true,
			Category:    "Gaming",
			Description: "Servidor oficial de partidas competitivas e ranked matches.",
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
			ID:          "2",
			Name:        "Dev Lounge",
			Banner:      "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1400&h=420&fit=crop&auto=format",
			IsPublic:    true,
			Category:    "Programação",
			Description: "Espaço para desenvolvedores discutirem código, arquitetura e carreira.",
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
			ID:          "3",
			Name:        "Le Mans Ultimate",
			Banner:      "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=1400&h=420&fit=crop&auto=format",
			IsPublic:    true,
			Category:    "Gaming",
			Description: "Comunidade de automobilismo virtual e simuladores de endurance.",
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
			ID:          "4",
			Name:        "Minecraft Realm",
			Banner:      "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1400&h=420&fit=crop&auto=format",
			IsPublic:    true,
			Category:    "Gaming",
			Description: "Mundo survival comunitário com vilas e projetos gigantes.",
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
			ID:          "5",
			Name:        "CS2 Tactics",
			Banner:      "https://images.unsplash.com/photo-1547394765-185e1e68f34e?w=1400&h=420&fit=crop&auto=format",
			IsPublic:    false,
			Category:    "Gaming",
			Description: "Treinos fechados e táticas exclusivas da equipe.",
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
			ID:          "6",
			Name:        "Study Group",
			Banner:      "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1400&h=420&fit=crop&auto=format",
			IsPublic:    true,
			Category:    "Estudos",
			Description: "Salas de foco e pomodoro para estudos em grupo.",
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
			IsPublic:    sData.IsPublic,
			Category:    sData.Category,
			Description: sData.Description,
			MemberCount: 100,
			CreatedAt:   time.Now(),
		}
		r.servers[srv.ID] = srv

		if r.members[srv.ID] == nil {
			r.members[srv.ID] = make(map[string]time.Time)
		}
		r.members[srv.ID][adminUser.ID] = time.Now()

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
	if user.Name == "" {
		user.Name = user.Username
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

func (r *MemoryRepository) GetUserByEmailOrUsername(login string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	clean := strings.ToLower(strings.TrimSpace(login))
	for _, u := range r.users {
		if strings.ToLower(u.Email) == clean || strings.ToLower(u.Username) == clean {
			return u, nil
		}
	}
	return nil, ErrNotFound
}

func (r *MemoryRepository) UpdateUser(user *models.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	cleanEmail := strings.ToLower(strings.TrimSpace(user.Email))
	cleanUsername := strings.ToLower(strings.TrimSpace(user.Username))

	for _, u := range r.users {
		if u.ID != user.ID {
			if strings.ToLower(u.Email) == cleanEmail || strings.ToLower(u.Username) == cleanUsername {
				return ErrAlreadyExists
			}
		}
	}

	u, ok := r.users[user.ID]
	if !ok {
		return ErrNotFound
	}

	u.Name = user.Name
	u.Username = user.Username
	u.Email = user.Email
	if user.AvatarURL != "" {
		u.AvatarURL = user.AvatarURL
	}
	return nil
}

func (r *MemoryRepository) UpdateUserPassword(id, hashedPassword string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	u, ok := r.users[id]
	if !ok {
		return ErrNotFound
	}
	u.Password = hashedPassword
	return nil
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

	if r.members[server.ID] == nil {
		r.members[server.ID] = make(map[string]time.Time)
	}
	r.members[server.ID][server.OwnerID] = server.CreatedAt
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

func (r *MemoryRepository) UpdateServer(server *models.Server) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	srv, ok := r.servers[server.ID]
	if !ok {
		return ErrNotFound
	}
	srv.Name = server.Name
	srv.IconURL = server.IconURL
	srv.IsPublic = server.IsPublic
	srv.Description = server.Description
	srv.Category = server.Category
	return nil
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
			ownerCopy := *owner
			if ownerCopy.Name == "" {
				ownerCopy.Name = ownerCopy.Username
			}
			return []*models.ServerMember{
				{
					ServerID: serverID,
					UserID:   owner.ID,
					User:     &ownerCopy,
					Role:     "owner",
					JoinedAt: srv.CreatedAt,
					Roles:    r.getMemberRolesInternal(serverID, owner.ID),
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
		uCopy := *u
		if uCopy.Name == "" {
			uCopy.Name = uCopy.Username
		}
		role := "member"
		if uid == srv.OwnerID {
			role = "owner"
		}
		result = append(result, &models.ServerMember{
			ServerID: serverID,
			UserID:   uid,
			User:     &uCopy,
			Role:     role,
			JoinedAt: joinedAt,
			Roles:    r.getMemberRolesInternal(serverID, uid),
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

func (r *MemoryRepository) getMemberRolesInternal(serverID, userID string) []*models.ServerRole {
	res := make([]*models.ServerRole, 0)
	if sMap, ok := r.memberRoles[serverID]; ok {
		if roleIDs, ok := sMap[userID]; ok {
			for _, rid := range roleIDs {
				if role, exists := r.roles[rid]; exists {
					res = append(res, role)
				}
			}
		}
	}
	return res
}

// ListPublicServers lista servidores públicos com metadados do usuário solicitante
func (r *MemoryRepository) ListPublicServers(userID string) ([]*models.PublicServerDTO, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.PublicServerDTO
	for _, s := range r.servers {
		if !s.IsPublic {
			continue
		}

		memberCount := len(r.members[s.ID])
		if memberCount == 0 {
			memberCount = s.MemberCount
			if memberCount == 0 {
				memberCount = 1
			}
		}

		isMember := false
		if membersMap, ok := r.members[s.ID]; ok {
			if _, exists := membersMap[userID]; exists {
				isMember = true
			}
		} else if s.OwnerID == userID {
			isMember = true
		}

		joinStatus := ""
		for _, req := range r.joinRequests {
			if req.ServerID == s.ID && req.UserID == userID {
				joinStatus = req.Status
				break
			}
		}

		sCopy := *s
		sCopy.MemberCount = memberCount
		if joinStatus == "" {
			joinStatus = "none"
		}

		result = append(result, &models.PublicServerDTO{
			Server:            sCopy,
			IsMember:          isMember,
			JoinRequestStatus: joinStatus,
		})
	}
	return result, nil
}

// CreateJoinRequest cria uma solicitação de entrada em servidor público
func (r *MemoryRepository) CreateJoinRequest(req *models.ServerJoinRequest) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Checa se já é membro
	if membersMap, ok := r.members[req.ServerID]; ok {
		if _, exists := membersMap[req.UserID]; exists {
			return errors.New("usuário já é membro deste servidor")
		}
	}

	// Checa se já existe pedido pendente
	for _, existing := range r.joinRequests {
		if existing.ServerID == req.ServerID && existing.UserID == req.UserID && existing.Status == "pending" {
			return errors.New("já existe um pedido pendente para este servidor")
		}
	}

	if req.ID == "" {
		req.ID = "req_" + uuid.New().String()
	}
	if req.CreatedAt.IsZero() {
		req.CreatedAt = time.Now()
	}
	if req.Status == "" {
		req.Status = "pending"
	}
	r.joinRequests[req.ID] = req
	return nil
}

// GetJoinRequest busca solicitação por servidor e usuário
func (r *MemoryRepository) GetJoinRequest(serverID, userID string) (*models.ServerJoinRequest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, req := range r.joinRequests {
		if req.ServerID == serverID && req.UserID == userID {
			reqCopy := *req
			if u, exists := r.users[req.UserID]; exists {
				reqCopy.User = u
			}
			return &reqCopy, nil
		}
	}
	return nil, ErrNotFound
}

// ListJoinRequests lista solicitações para moderadores
func (r *MemoryRepository) ListJoinRequests(serverID string, status string) ([]*models.ServerJoinRequest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.ServerJoinRequest
	for _, req := range r.joinRequests {
		if req.ServerID != serverID {
			continue
		}
		if status != "" && req.Status != status {
			continue
		}
		reqCopy := *req
		if u, exists := r.users[req.UserID]; exists {
			reqCopy.User = u
		}
		result = append(result, &reqCopy)
	}
	return result, nil
}

// ReviewJoinRequest aprova ou rejeita solicitação
func (r *MemoryRepository) ReviewJoinRequest(requestID, reviewerID, status string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	req, ok := r.joinRequests[requestID]
	if !ok {
		return ErrNotFound
	}

	now := time.Now()
	req.Status = status
	req.ReviewedBy = &reviewerID
	req.ReviewedAt = &now

	if status == "approved" {
		if r.members[req.ServerID] == nil {
			r.members[req.ServerID] = make(map[string]time.Time)
		}
		r.members[req.ServerID][req.UserID] = now
	}
	return nil
}

// CreateRole cria um novo cargo
func (r *MemoryRepository) CreateRole(role *models.ServerRole) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if role.ID == "" {
		role.ID = "role_" + uuid.New().String()
	}
	if role.CreatedAt.IsZero() {
		role.CreatedAt = time.Now()
	}
	if role.Permissions == nil {
		role.Permissions = make(map[string]bool)
	}
	r.roles[role.ID] = role
	return nil
}

// GetRoleByID busca cargo por ID
func (r *MemoryRepository) GetRoleByID(roleID string) (*models.ServerRole, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	role, ok := r.roles[roleID]
	if !ok {
		return nil, ErrNotFound
	}
	return role, nil
}

// UpdateRole atualiza cargo
func (r *MemoryRepository) UpdateRole(role *models.ServerRole) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, ok := r.roles[role.ID]
	if !ok {
		return ErrNotFound
	}
	existing.Name = role.Name
	existing.Color = role.Color
	existing.Position = role.Position
	if role.Permissions != nil {
		existing.Permissions = role.Permissions
	}
	return nil
}

// DeleteRole remove cargo
func (r *MemoryRepository) DeleteRole(roleID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.roles, roleID)

	for serverID, userMap := range r.memberRoles {
		for userID, roleIDs := range userMap {
			var filtered []string
			for _, rid := range roleIDs {
				if rid != roleID {
					filtered = append(filtered, rid)
				}
			}
			r.memberRoles[serverID][userID] = filtered
		}
	}
	return nil
}

// ListServerRoles lista cargos de um servidor
func (r *MemoryRepository) ListServerRoles(serverID string) ([]*models.ServerRole, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*models.ServerRole
	for _, role := range r.roles {
		if role.ServerID == serverID {
			result = append(result, role)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Position < result[j].Position
	})
	return result, nil
}

// AssignMemberRole atribui cargo a membro
func (r *MemoryRepository) AssignMemberRole(serverID, userID, roleID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.memberRoles[serverID] == nil {
		r.memberRoles[serverID] = make(map[string][]string)
	}
	for _, rid := range r.memberRoles[serverID][userID] {
		if rid == roleID {
			return nil
		}
	}
	r.memberRoles[serverID][userID] = append(r.memberRoles[serverID][userID], roleID)
	return nil
}

// RemoveMemberRole remove cargo de membro
func (r *MemoryRepository) RemoveMemberRole(serverID, userID, roleID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.memberRoles[serverID] == nil {
		return nil
	}
	var filtered []string
	for _, rid := range r.memberRoles[serverID][userID] {
		if rid != roleID {
			filtered = append(filtered, rid)
		}
	}
	r.memberRoles[serverID][userID] = filtered
	return nil
}

// GetMemberRoles lista cargos atribuídos a membro
func (r *MemoryRepository) GetMemberRoles(serverID, userID string) ([]*models.ServerRole, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	return r.getMemberRolesInternal(serverID, userID), nil
}

// HasServerPermission verifica se usuário possui permissão no servidor
func (r *MemoryRepository) HasServerPermission(serverID, userID string, permission string) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	srv, ok := r.servers[serverID]
	if !ok {
		return false, ErrNotFound
	}
	if srv.OwnerID == userID {
		return true, nil
	}

	roles := r.getMemberRolesInternal(serverID, userID)
	for _, role := range roles {
		if role.Permissions != nil && role.Permissions[permission] {
			return true, nil
		}
	}
	return false, nil
}

// Ping simula teste de integridade da memória
func (r *MemoryRepository) Ping(_ context.Context) error {
	return nil
}

