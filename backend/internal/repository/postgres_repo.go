package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/projectnbx/backend/internal/models"
)

type PostgresRepository struct {
	db *sql.DB
}

func NewPostgresRepository(db *sql.DB) *PostgresRepository {
	return &PostgresRepository{db: db}
}

// User methods
func (r *PostgresRepository) CreateUser(user *models.User) error {
	if user.ID == "" {
		user.ID = "usr_" + uuid.New().String()
	}
	if user.Name == "" {
		user.Name = user.Username
	}
	user.CreatedAt = time.Now()

	query := `
	INSERT INTO users (id, name, username, email, password, avatar_url, status, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`

	_, err := r.db.Exec(query,
		user.ID,
		user.Name,
		user.Username,
		user.Email,
		user.Password,
		user.AvatarURL,
		user.Status,
		user.CreatedAt,
		time.Now(),
	)

	if err != nil {
		var pqErr *pq.Error
		if errors.As(err, &pqErr) && pqErr.Code == "23505" { // Unique violation
			return ErrAlreadyExists
		}
		return err
	}
	return nil
}

func (r *PostgresRepository) GetUserByID(id string) (*models.User, error) {
	query := `
	SELECT id, COALESCE(name, ''), username, email, password, COALESCE(avatar_url, ''), status, created_at
	FROM users WHERE id = $1`

	user := &models.User{}
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Name,
		&user.Username,
		&user.Email,
		&user.Password,
		&user.AvatarURL,
		&user.Status,
		&user.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return user, nil
}

func (r *PostgresRepository) GetUserByEmail(email string) (*models.User, error) {
	query := `
	SELECT id, COALESCE(name, ''), username, email, password, COALESCE(avatar_url, ''), status, created_at
	FROM users WHERE LOWER(email) = LOWER($1)`

	user := &models.User{}
	err := r.db.QueryRow(query, email).Scan(
		&user.ID,
		&user.Name,
		&user.Username,
		&user.Email,
		&user.Password,
		&user.AvatarURL,
		&user.Status,
		&user.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return user, nil
}

func (r *PostgresRepository) GetUserByEmailOrUsername(identifier string) (*models.User, error) {
	query := `
	SELECT id, COALESCE(name, ''), username, email, password, COALESCE(avatar_url, ''), status, created_at
	FROM users WHERE LOWER(email) = LOWER($1) OR LOWER(username) = LOWER($1)
	LIMIT 1`

	user := &models.User{}
	err := r.db.QueryRow(query, identifier).Scan(
		&user.ID,
		&user.Name,
		&user.Username,
		&user.Email,
		&user.Password,
		&user.AvatarURL,
		&user.Status,
		&user.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return user, nil
}

func (r *PostgresRepository) UpdateUser(user *models.User) error {
	query := `
	UPDATE users SET name = $1, username = $2, email = $3, updated_at = $4
	WHERE id = $5`

	res, err := r.db.Exec(query, user.Name, user.Username, user.Email, time.Now(), user.ID)
	if err != nil {
		var pqErr *pq.Error
		if errors.As(err, &pqErr) && pqErr.Code == "23505" {
			return ErrAlreadyExists
		}
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) UpdateUserPassword(id, hashedPassword string) error {
	query := `UPDATE users SET password = $1, updated_at = $2 WHERE id = $3`
	res, err := r.db.Exec(query, hashedPassword, time.Now(), id)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) UpdateUserStatus(id, status string) error {
	query := `UPDATE users SET status = $1, updated_at = $2 WHERE id = $3`
	res, err := r.db.Exec(query, status, time.Now(), id)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// Server methods
func (r *PostgresRepository) CreateServer(server *models.Server) error {
	if server.ID == "" {
		server.ID = "srv_" + uuid.New().String()
	}
	if server.MemberCount <= 0 {
		server.MemberCount = 1
	}
	if server.Category == "" {
		server.Category = "Comunidade Geral"
	}
	if server.CreatedAt.IsZero() {
		server.CreatedAt = time.Now()
	}

	query := `
	INSERT INTO servers (id, name, icon_url, owner_id, member_count, is_public, description, category, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`

	_, err := r.db.Exec(query,
		server.ID,
		server.Name,
		server.IconURL,
		server.OwnerID,
		server.MemberCount,
		server.IsPublic,
		server.Description,
		server.Category,
		server.CreatedAt,
		time.Now(),
	)
	if err != nil {
		return err
	}

	if server.OwnerID != "" {
		_ = r.AddServerMember(server.ID, server.OwnerID)
	}
	return nil
}

func (r *PostgresRepository) GetServerByID(id string) (*models.Server, error) {
	query := `
	SELECT id, name, COALESCE(icon_url, ''), owner_id, member_count, COALESCE(is_public, FALSE), COALESCE(description, ''), COALESCE(category, 'Comunidade Geral'), created_at
	FROM servers WHERE id = $1`

	srv := &models.Server{}
	err := r.db.QueryRow(query, id).Scan(
		&srv.ID,
		&srv.Name,
		&srv.IconURL,
		&srv.OwnerID,
		&srv.MemberCount,
		&srv.IsPublic,
		&srv.Description,
		&srv.Category,
		&srv.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	channels, err := r.ListChannelsByServer(id)
	if err == nil {
		srv.Channels = channels
	}
	return srv, nil
}

func (r *PostgresRepository) ListServers() ([]*models.Server, error) {
	query := `
	SELECT id, name, COALESCE(icon_url, ''), owner_id, member_count, COALESCE(is_public, FALSE), COALESCE(description, ''), COALESCE(category, 'Comunidade Geral'), created_at
	FROM servers ORDER BY created_at ASC`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	servers := make([]*models.Server, 0)
	for rows.Next() {
		srv := &models.Server{}
		if err := rows.Scan(
			&srv.ID,
			&srv.Name,
			&srv.IconURL,
			&srv.OwnerID,
			&srv.MemberCount,
			&srv.IsPublic,
			&srv.Description,
			&srv.Category,
			&srv.CreatedAt,
		); err != nil {
			return nil, err
		}

		channels, _ := r.ListChannelsByServer(srv.ID)
		srv.Channels = channels
		servers = append(servers, srv)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return servers, nil
}

// Channel methods
func (r *PostgresRepository) CreateChannel(channel *models.Channel) error {
	if channel.ID == "" {
		channel.ID = "chn_" + uuid.New().String()
	}
	channel.CreatedAt = time.Now()

	query := `
	INSERT INTO channels (id, server_id, name, type, position, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err := r.db.Exec(query,
		channel.ID,
		channel.ServerID,
		channel.Name,
		channel.Type,
		channel.Position,
		channel.CreatedAt,
		time.Now(),
	)
	return err
}

func (r *PostgresRepository) GetChannelByID(id string) (*models.Channel, error) {
	query := `
	SELECT id, server_id, name, type, position, created_at
	FROM channels WHERE id = $1`

	ch := &models.Channel{}
	err := r.db.QueryRow(query, id).Scan(
		&ch.ID,
		&ch.ServerID,
		&ch.Name,
		&ch.Type,
		&ch.Position,
		&ch.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return ch, nil
}

func (r *PostgresRepository) ListChannelsByServer(serverID string) ([]*models.Channel, error) {
	query := `
	SELECT id, server_id, name, type, position, created_at
	FROM channels WHERE server_id = $1 ORDER BY position ASC, created_at ASC`

	rows, err := r.db.Query(query, serverID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	channels := make([]*models.Channel, 0)
	for rows.Next() {
		ch := &models.Channel{}
		if err := rows.Scan(
			&ch.ID,
			&ch.ServerID,
			&ch.Name,
			&ch.Type,
			&ch.Position,
			&ch.CreatedAt,
		); err != nil {
			return nil, err
		}
		channels = append(channels, ch)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return channels, nil
}

// Message methods
func (r *PostgresRepository) CreateMessage(msg *models.Message) error {
	if msg.ID == "" {
		msg.ID = "msg_" + uuid.New().String()
	}
	msg.CreatedAt = time.Now()

	query := `
	INSERT INTO messages (id, channel_id, server_id, author_id, content, created_at)
	VALUES ($1, $2, $3, $4, $5, $6)`

	_, err := r.db.Exec(query,
		msg.ID,
		msg.ChannelID,
		msg.ServerID,
		msg.AuthorID,
		msg.Content,
		msg.CreatedAt,
	)
	return err
}

func (r *PostgresRepository) GetMessageByID(id string) (*models.Message, error) {
	query := `
	SELECT m.id, m.channel_id, m.server_id, m.author_id, m.content, m.created_at,
	       u.id, u.username, u.email, COALESCE(u.avatar_url, ''), u.status, u.created_at
	FROM messages m
	JOIN users u ON m.author_id = u.id
	WHERE m.id = $1`

	row := r.db.QueryRow(query, id)
	msg := &models.Message{Author: &models.User{}}
	err := row.Scan(
		&msg.ID,
		&msg.ChannelID,
		&msg.ServerID,
		&msg.AuthorID,
		&msg.Content,
		&msg.CreatedAt,
		&msg.Author.ID,
		&msg.Author.Username,
		&msg.Author.Email,
		&msg.Author.AvatarURL,
		&msg.Author.Status,
		&msg.Author.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return msg, nil
}

func (r *PostgresRepository) UpdateMessage(id, content string) error {
	query := `UPDATE messages SET content = $1 WHERE id = $2`
	res, err := r.db.Exec(query, content, id)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) DeleteMessage(id string) error {
	query := `DELETE FROM messages WHERE id = $1`
	res, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) ListMessagesByChannel(channelID string, limit int) ([]*models.Message, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	query := `
	SELECT m.id, m.channel_id, m.server_id, m.author_id, m.content, m.created_at,
	       u.id, u.username, u.email, COALESCE(u.avatar_url, ''), u.status, u.created_at
	FROM messages m
	JOIN users u ON m.author_id = u.id
	WHERE m.channel_id = $1
	ORDER BY m.created_at DESC
	LIMIT $2`

	rows, err := r.db.Query(query, channelID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	msgs := make([]*models.Message, 0)
	for rows.Next() {
		msg := &models.Message{Author: &models.User{}}
		if err := rows.Scan(
			&msg.ID,
			&msg.ChannelID,
			&msg.ServerID,
			&msg.AuthorID,
			&msg.Content,
			&msg.CreatedAt,
			&msg.Author.ID,
			&msg.Author.Username,
			&msg.Author.Email,
			&msg.Author.AvatarURL,
			&msg.Author.Status,
			&msg.Author.CreatedAt,
		); err != nil {
			return nil, err
		}
		msgs = append(msgs, msg)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Inverter para ordem cronológica crescente
	for i, j := 0, len(msgs)-1; i < j; i, j = i+1, j-1 {
		msgs[i], msgs[j] = msgs[j], msgs[i]
	}
	return msgs, nil
}

// Audit methods
func (r *PostgresRepository) CreateAuditLog(log *models.AuditLog) error {
	if log.ID == "" {
		log.ID = "aud_" + uuid.New().String()
	}
	if log.CreatedAt.IsZero() {
		log.CreatedAt = time.Now()
	}

	metadataJSON, err := json.Marshal(log.Metadata)
	if err != nil {
		metadataJSON = []byte("{}")
	}

	query := `
	INSERT INTO audit_logs (id, source, action, user_id, resource_id, ip_address, user_agent, metadata, created_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`

	_, err = r.db.Exec(query,
		log.ID,
		string(log.Source),
		log.Action,
		log.UserID,
		log.ResourceID,
		log.IPAddress,
		log.UserAgent,
		metadataJSON,
		log.CreatedAt,
	)
	return err
}

func (r *PostgresRepository) ListAuditLogs(limit int, source models.AuditSource) ([]*models.AuditLog, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	var rows *sql.Rows
	var err error

	if source != "" {
		query := `
		SELECT id, source, action, user_id, resource_id, COALESCE(ip_address, ''), COALESCE(user_agent, ''), metadata, created_at
		FROM audit_logs
		WHERE source = $1
		ORDER BY created_at DESC
		LIMIT $2`
		rows, err = r.db.Query(query, string(source), limit)
	} else {
		query := `
		SELECT id, source, action, user_id, resource_id, COALESCE(ip_address, ''), COALESCE(user_agent, ''), metadata, created_at
		FROM audit_logs
		ORDER BY created_at DESC
		LIMIT $1`
		rows, err = r.db.Query(query, limit)
	}

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	logs := make([]*models.AuditLog, 0)
	for rows.Next() {
		item := &models.AuditLog{}
		var metadataBytes []byte
		var srcStr string

		if err := rows.Scan(
			&item.ID,
			&srcStr,
			&item.Action,
			&item.UserID,
			&item.ResourceID,
			&item.IPAddress,
			&item.UserAgent,
			&metadataBytes,
			&item.CreatedAt,
		); err != nil {
			return nil, err
		}

		item.Source = models.AuditSource(srcStr)
		if len(metadataBytes) > 0 {
			_ = json.Unmarshal(metadataBytes, &item.Metadata)
		}
		logs = append(logs, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return logs, nil
}

// Server Member Methods
func (r *PostgresRepository) AddServerMember(serverID, userID string) error {
	query := `
	INSERT INTO server_members (server_id, user_id, joined_at)
	VALUES ($1, $2, $3)
	ON CONFLICT (server_id, user_id) DO NOTHING`
	_, err := r.db.Exec(query, serverID, userID, time.Now())
	if err == nil {
		countQuery := `UPDATE servers SET member_count = (SELECT COUNT(*) FROM server_members WHERE server_id = $1) WHERE id = $1`
		_, _ = r.db.Exec(countQuery, serverID)
	}
	return err
}

func (r *PostgresRepository) RemoveServerMember(serverID, userID string) error {
	query := `DELETE FROM server_members WHERE server_id = $1 AND user_id = $2`
	_, err := r.db.Exec(query, serverID, userID)
	if err == nil {
		countQuery := `UPDATE servers SET member_count = (SELECT COUNT(*) FROM server_members WHERE server_id = $1) WHERE id = $1`
		_, _ = r.db.Exec(countQuery, serverID)
	}
	return err
}

func (r *PostgresRepository) ListServerMembers(serverID string) ([]*models.ServerMember, error) {
	query := `
	SELECT sm.server_id, sm.user_id, sm.joined_at, s.owner_id,
	       u.username, u.email, COALESCE(u.avatar_url, ''), u.status, u.created_at
	FROM server_members sm
	JOIN servers s ON s.id = sm.server_id
	JOIN users u ON u.id = sm.user_id
	WHERE sm.server_id = $1
	ORDER BY sm.joined_at ASC`

	rows, err := r.db.Query(query, serverID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	members := make([]*models.ServerMember, 0)
	for rows.Next() {
		var sm models.ServerMember
		var ownerID string
		var u models.User
		if err := rows.Scan(
			&sm.ServerID,
			&sm.UserID,
			&sm.JoinedAt,
			&ownerID,
			&u.Username,
			&u.Email,
			&u.AvatarURL,
			&u.Status,
			&u.CreatedAt,
		); err != nil {
			return nil, err
		}
		u.ID = sm.UserID
		sm.User = &u
		if sm.UserID == ownerID {
			sm.Role = "owner"
		} else {
			sm.Role = "member"
		}
		roles, _ := r.GetMemberRoles(serverID, sm.UserID)
		sm.Roles = roles
		members = append(members, &sm)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return members, nil
}

func (r *PostgresRepository) IsServerMember(serverID, userID string) (bool, error) {
	var exists bool
	query := `
	SELECT EXISTS (
		SELECT 1 FROM servers WHERE id = $1 AND owner_id = $2
		UNION
		SELECT 1 FROM server_members WHERE server_id = $1 AND user_id = $2
	)`
	err := r.db.QueryRow(query, serverID, userID).Scan(&exists)
	return exists, err
}

func (r *PostgresRepository) FindUser(query string) (*models.User, error) {
	q := `
	SELECT id, COALESCE(name, ''), username, email, COALESCE(avatar_url, ''), status, created_at
	FROM users
	WHERE LOWER(username) = LOWER($1) OR LOWER(email) = LOWER($1) OR id = $1
	LIMIT 1`

	u := &models.User{}
	err := r.db.QueryRow(q, query).Scan(
		&u.ID,
		&u.Name,
		&u.Username,
		&u.Email,
		&u.AvatarURL,
		&u.Status,
		&u.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return u, nil
}

func (r *PostgresRepository) SearchUsers(query string, limit int) ([]*models.User, error) {
	if limit <= 0 || limit > 20 {
		limit = 10
	}

	q := `
	SELECT id, COALESCE(name, ''), username, email, COALESCE(avatar_url, ''), status, created_at
	FROM users
	WHERE LOWER(username) LIKE LOWER($1) OR LOWER(email) LIKE LOWER($1) OR LOWER(name) LIKE LOWER($1)
	LIMIT $2`

	rows, err := r.db.Query(q, "%"+query+"%", limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	users := make([]*models.User, 0)
	for rows.Next() {
		u := &models.User{}
		if err := rows.Scan(
			&u.ID,
			&u.Name,
			&u.Username,
			&u.Email,
			&u.AvatarURL,
			&u.Status,
			&u.CreatedAt,
		); err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return users, nil
}

// Invite Methods
func (r *PostgresRepository) CreateInvite(invite *models.ServerInvite) error {
	if invite.CreatedAt.IsZero() {
		invite.CreatedAt = time.Now()
	}
	query := `
	INSERT INTO server_invites (code, server_id, creator_id, max_uses, uses_count, expires_at, created_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err := r.db.Exec(
		query,
		invite.Code,
		invite.ServerID,
		invite.CreatorID,
		invite.MaxUses,
		invite.UsesCount,
		invite.ExpiresAt,
		invite.CreatedAt,
	)
	return err
}

func (r *PostgresRepository) GetInviteByCode(code string) (*models.ServerInvite, error) {
	query := `
	SELECT i.code, i.server_id, i.creator_id, i.max_uses, i.uses_count, i.expires_at, i.created_at,
	       u.id, u.username, u.email, COALESCE(u.avatar_url, ''), u.status, u.created_at
	FROM server_invites i
	JOIN users u ON i.creator_id = u.id
	WHERE i.code = $1`

	invite := &models.ServerInvite{Creator: &models.User{}}
	var expiresAt sql.NullTime

	err := r.db.QueryRow(query, code).Scan(
		&invite.Code,
		&invite.ServerID,
		&invite.CreatorID,
		&invite.MaxUses,
		&invite.UsesCount,
		&expiresAt,
		&invite.CreatedAt,
		&invite.Creator.ID,
		&invite.Creator.Username,
		&invite.Creator.Email,
		&invite.Creator.AvatarURL,
		&invite.Creator.Status,
		&invite.Creator.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	if expiresAt.Valid {
		invite.ExpiresAt = &expiresAt.Time
		if time.Now().After(expiresAt.Time) {
			invite.IsExpired = true
		}
	}
	if invite.MaxUses > 0 && invite.UsesCount >= invite.MaxUses {
		invite.IsExhausted = true
	}

	return invite, nil
}

func (r *PostgresRepository) IncrementInviteUses(code string) error {
	query := `UPDATE server_invites SET uses_count = uses_count + 1 WHERE code = $1 AND (max_uses = 0 OR uses_count < max_uses)`
	res, err := r.db.Exec(query, code)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrMaxUsesReached
	}
	return nil
}

func (r *PostgresRepository) ListServerInvites(serverID string) ([]*models.ServerInvite, error) {
	query := `
	SELECT i.code, i.server_id, i.creator_id, i.max_uses, i.uses_count, i.expires_at, i.created_at,
	       u.id, u.username, u.email, COALESCE(u.avatar_url, ''), u.status, u.created_at
	FROM server_invites i
	JOIN users u ON i.creator_id = u.id
	WHERE i.server_id = $1
	ORDER BY i.created_at DESC`

	rows, err := r.db.Query(query, serverID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	invites := make([]*models.ServerInvite, 0)
	now := time.Now()

	for rows.Next() {
		invite := &models.ServerInvite{Creator: &models.User{}}
		var expiresAt sql.NullTime

		if err := rows.Scan(
			&invite.Code,
			&invite.ServerID,
			&invite.CreatorID,
			&invite.MaxUses,
			&invite.UsesCount,
			&expiresAt,
			&invite.CreatedAt,
			&invite.Creator.ID,
			&invite.Creator.Username,
			&invite.Creator.Email,
			&invite.Creator.AvatarURL,
			&invite.Creator.Status,
			&invite.Creator.CreatedAt,
		); err != nil {
			return nil, err
		}

		if expiresAt.Valid {
			invite.ExpiresAt = &expiresAt.Time
			if now.After(expiresAt.Time) {
				invite.IsExpired = true
			}
		}
		if invite.MaxUses > 0 && invite.UsesCount >= invite.MaxUses {
			invite.IsExhausted = true
		}

		invites = append(invites, invite)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return invites, nil
}

func (r *PostgresRepository) DeleteInvite(code string) error {
	query := `DELETE FROM server_invites WHERE code = $1`
	_, err := r.db.Exec(query, code)
	return err
}

// Ping verifica se a conexão com o banco de dados PostgreSQL está ativa
func (r *PostgresRepository) Ping(ctx context.Context) error {
	return r.db.PingContext(ctx)
}

// ==========================================
// Servidores Públicos & Descoberta
// ==========================================

func (r *PostgresRepository) ListPublicServers(userID string) ([]*models.PublicServerDTO, error) {
	query := `
	SELECT s.id, s.name, COALESCE(s.icon_url, ''), s.owner_id, s.member_count, s.is_public,
	       COALESCE(s.description, ''), COALESCE(s.category, 'Comunidade Geral'), s.created_at,
	       EXISTS(SELECT 1 FROM server_members sm WHERE sm.server_id = s.id AND sm.user_id = $1) as is_member,
	       COALESCE((SELECT jr.status FROM server_join_requests jr WHERE jr.server_id = s.id AND jr.user_id = $1 ORDER BY jr.created_at DESC LIMIT 1), 'none') as join_request_status
	FROM servers s
	WHERE s.is_public = TRUE
	ORDER BY s.member_count DESC, s.created_at DESC`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	list := make([]*models.PublicServerDTO, 0)
	for rows.Next() {
		var dto models.PublicServerDTO
		if err := rows.Scan(
			&dto.ID,
			&dto.Name,
			&dto.IconURL,
			&dto.OwnerID,
			&dto.MemberCount,
			&dto.IsPublic,
			&dto.Description,
			&dto.Category,
			&dto.CreatedAt,
			&dto.IsMember,
			&dto.JoinRequestStatus,
		); err != nil {
			return nil, err
		}
		channels, _ := r.ListChannelsByServer(dto.ID)
		dto.Channels = channels
		list = append(list, &dto)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return list, nil
}

// ==========================================
// Solicitações de Entrada (Join Requests)
// ==========================================

func (r *PostgresRepository) CreateJoinRequest(req *models.ServerJoinRequest) error {
	if req.ID == "" {
		req.ID = "req_" + uuid.New().String()
	}
	req.Status = "pending"
	req.CreatedAt = time.Now()

	query := `
	INSERT INTO server_join_requests (id, server_id, user_id, status, created_at)
	VALUES ($1, $2, $3, $4, $5)
	ON CONFLICT (server_id, user_id) 
	DO UPDATE SET status = 'pending', created_at = EXCLUDED.created_at, reviewed_by = NULL, reviewed_at = NULL`

	_, err := r.db.Exec(query, req.ID, req.ServerID, req.UserID, req.Status, req.CreatedAt)
	return err
}

func (r *PostgresRepository) GetJoinRequest(serverID, userID string) (*models.ServerJoinRequest, error) {
	query := `
	SELECT jr.id, jr.server_id, jr.user_id, jr.status, jr.created_at, jr.reviewed_by, jr.reviewed_at,
	       u.username, u.email, COALESCE(u.avatar_url, ''), u.status
	FROM server_join_requests jr
	JOIN users u ON u.id = jr.user_id
	WHERE jr.server_id = $1 AND jr.user_id = $2`

	var req models.ServerJoinRequest
	var u models.User
	var revBy sql.NullString
	var revAt sql.NullTime

	err := r.db.QueryRow(query, serverID, userID).Scan(
		&req.ID,
		&req.ServerID,
		&req.UserID,
		&req.Status,
		&req.CreatedAt,
		&revBy,
		&revAt,
		&u.Username,
		&u.Email,
		&u.AvatarURL,
		&u.Status,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	u.ID = req.UserID
	req.User = &u
	if revBy.Valid {
		req.ReviewedBy = &revBy.String
	}
	if revAt.Valid {
		req.ReviewedAt = &revAt.Time
	}
	return &req, nil
}

func (r *PostgresRepository) ListJoinRequests(serverID string, status string) ([]*models.ServerJoinRequest, error) {
	query := `
	SELECT jr.id, jr.server_id, jr.user_id, jr.status, jr.created_at, jr.reviewed_by, jr.reviewed_at,
	       u.username, u.email, COALESCE(u.avatar_url, ''), u.status
	FROM server_join_requests jr
	JOIN users u ON u.id = jr.user_id
	WHERE jr.server_id = $1`

	args := []interface{}{serverID}
	if status != "" {
		query += " AND jr.status = $2"
		args = append(args, status)
	}
	query += " ORDER BY jr.created_at ASC"

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	list := make([]*models.ServerJoinRequest, 0)
	for rows.Next() {
		var req models.ServerJoinRequest
		var u models.User
		var revBy sql.NullString
		var revAt sql.NullTime

		if err := rows.Scan(
			&req.ID,
			&req.ServerID,
			&req.UserID,
			&req.Status,
			&req.CreatedAt,
			&revBy,
			&revAt,
			&u.Username,
			&u.Email,
			&u.AvatarURL,
			&u.Status,
		); err != nil {
			return nil, err
		}

		u.ID = req.UserID
		req.User = &u
		if revBy.Valid {
			req.ReviewedBy = &revBy.String
		}
		if revAt.Valid {
			req.ReviewedAt = &revAt.Time
		}
		list = append(list, &req)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return list, nil
}

func (r *PostgresRepository) ReviewJoinRequest(requestID, reviewerID, status string) error {
	query := `
	UPDATE server_join_requests
	SET status = $1, reviewed_by = $2, reviewed_at = NOW()
	WHERE id = $3
	RETURNING server_id, user_id`

	var serverID, userID string
	err := r.db.QueryRow(query, status, reviewerID, requestID).Scan(&serverID, &userID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrNotFound
		}
		return err
	}

	if status == "approved" {
		return r.AddServerMember(serverID, userID)
	}
	return nil
}

// ==========================================
// Cargos do Servidor (Roles)
// ==========================================

func (r *PostgresRepository) CreateRole(role *models.ServerRole) error {
	if role.ID == "" {
		role.ID = "role_" + uuid.New().String()
	}
	if role.CreatedAt.IsZero() {
		role.CreatedAt = time.Now()
	}
	if role.Color == 0 {
		role.Color = 4126743207 // 0xFFF5CBA7
	}
	if role.Permissions == nil {
		role.Permissions = make(map[string]bool)
	}

	permJSON, err := json.Marshal(role.Permissions)
	if err != nil {
		permJSON = []byte("{}")
	}

	query := `
	INSERT INTO server_roles (id, server_id, name, color, position, permissions, created_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err = r.db.Exec(query,
		role.ID,
		role.ServerID,
		role.Name,
		role.Color,
		role.Position,
		permJSON,
		role.CreatedAt,
	)
	return err
}

func (r *PostgresRepository) GetRoleByID(id string) (*models.ServerRole, error) {
	query := `
	SELECT id, server_id, name, color, position, permissions, created_at
	FROM server_roles WHERE id = $1`

	var role models.ServerRole
	var permJSON []byte

	err := r.db.QueryRow(query, id).Scan(
		&role.ID,
		&role.ServerID,
		&role.Name,
		&role.Color,
		&role.Position,
		&permJSON,
		&role.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	role.Permissions = make(map[string]bool)
	if len(permJSON) > 0 {
		_ = json.Unmarshal(permJSON, &role.Permissions)
	}
	return &role, nil
}

func (r *PostgresRepository) UpdateRole(role *models.ServerRole) error {
	if role.Permissions == nil {
		role.Permissions = make(map[string]bool)
	}
	permJSON, err := json.Marshal(role.Permissions)
	if err != nil {
		permJSON = []byte("{}")
	}

	query := `
	UPDATE server_roles
	SET name = $1, color = $2, position = $3, permissions = $4
	WHERE id = $5 AND server_id = $6`

	res, err := r.db.Exec(query, role.Name, role.Color, role.Position, permJSON, role.ID, role.ServerID)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) DeleteRole(roleID string) error {
	query := `DELETE FROM server_roles WHERE id = $1`
	res, err := r.db.Exec(query, roleID)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) ListServerRoles(serverID string) ([]*models.ServerRole, error) {
	query := `
	SELECT id, server_id, name, color, position, permissions, created_at
	FROM server_roles
	WHERE server_id = $1
	ORDER BY position ASC, created_at ASC`

	rows, err := r.db.Query(query, serverID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	roles := make([]*models.ServerRole, 0)
	for rows.Next() {
		var role models.ServerRole
		var permJSON []byte
		if err := rows.Scan(
			&role.ID,
			&role.ServerID,
			&role.Name,
			&role.Color,
			&role.Position,
			&permJSON,
			&role.CreatedAt,
		); err != nil {
			return nil, err
		}
		role.Permissions = make(map[string]bool)
		if len(permJSON) > 0 {
			_ = json.Unmarshal(permJSON, &role.Permissions)
		}
		roles = append(roles, &role)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return roles, nil
}

func (r *PostgresRepository) AssignMemberRole(serverID, userID, roleID string) error {
	query := `
	INSERT INTO server_member_roles (server_id, user_id, role_id)
	VALUES ($1, $2, $3)
	ON CONFLICT DO NOTHING`
	_, err := r.db.Exec(query, serverID, userID, roleID)
	return err
}

func (r *PostgresRepository) RemoveMemberRole(serverID, userID, roleID string) error {
	query := `DELETE FROM server_member_roles WHERE server_id = $1 AND user_id = $2 AND role_id = $3`
	_, err := r.db.Exec(query, serverID, userID, roleID)
	return err
}

func (r *PostgresRepository) GetMemberRoles(serverID, userID string) ([]*models.ServerRole, error) {
	query := `
	SELECT sr.id, sr.server_id, sr.name, sr.color, sr.position, sr.permissions, sr.created_at
	FROM server_roles sr
	JOIN server_member_roles smr ON smr.role_id = sr.id
	WHERE smr.server_id = $1 AND smr.user_id = $2
	ORDER BY sr.position ASC, sr.created_at ASC`

	rows, err := r.db.Query(query, serverID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	roles := make([]*models.ServerRole, 0)
	for rows.Next() {
		var role models.ServerRole
		var permJSON []byte
		if err := rows.Scan(
			&role.ID,
			&role.ServerID,
			&role.Name,
			&role.Color,
			&role.Position,
			&permJSON,
			&role.CreatedAt,
		); err != nil {
			return nil, err
		}
		role.Permissions = make(map[string]bool)
		if len(permJSON) > 0 {
			_ = json.Unmarshal(permJSON, &role.Permissions)
		}
		roles = append(roles, &role)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return roles, nil
}

func (r *PostgresRepository) HasServerPermission(serverID, userID, permission string) (bool, error) {
	// 1. O dono do servidor tem todas as permissões irrestritas
	var ownerID string
	err := r.db.QueryRow(`SELECT owner_id FROM servers WHERE id = $1`, serverID).Scan(&ownerID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return false, ErrNotFound
		}
		return false, err
	}
	if ownerID == userID {
		return true, nil
	}

	// 2. Consulta permissões concedidas pelos cargos atribuídos
	roles, err := r.GetMemberRoles(serverID, userID)
	if err != nil {
		return false, err
	}
	for _, role := range roles {
		if role.Permissions != nil && role.Permissions[permission] {
			return true, nil
		}
	}
	return false, nil
}


