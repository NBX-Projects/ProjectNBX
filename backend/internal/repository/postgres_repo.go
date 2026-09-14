package repository

import (
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
	user.CreatedAt = time.Now()

	query := `
	INSERT INTO users (id, username, email, password, avatar_url, status, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`

	_, err := r.db.Exec(query,
		user.ID,
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
	SELECT id, username, email, password, COALESCE(avatar_url, ''), status, created_at
	FROM users WHERE id = $1`

	user := &models.User{}
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
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
	SELECT id, username, email, password, COALESCE(avatar_url, ''), status, created_at
	FROM users WHERE LOWER(email) = LOWER($1)`

	user := &models.User{}
	err := r.db.QueryRow(query, email).Scan(
		&user.ID,
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

	query := `
	INSERT INTO servers (id, name, icon_url, owner_id, member_count, created_at, updated_at)
	VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err := r.db.Exec(query,
		server.ID,
		server.Name,
		server.IconURL,
		server.OwnerID,
		server.MemberCount,
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
	SELECT id, name, COALESCE(icon_url, ''), owner_id, member_count, created_at
	FROM servers WHERE id = $1`

	srv := &models.Server{}
	err := r.db.QueryRow(query, id).Scan(
		&srv.ID,
		&srv.Name,
		&srv.IconURL,
		&srv.OwnerID,
		&srv.MemberCount,
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
	SELECT id, name, COALESCE(icon_url, ''), owner_id, member_count, created_at
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
		members = append(members, &sm)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return members, nil
}

func (r *PostgresRepository) FindUser(query string) (*models.User, error) {
	q := `
	SELECT id, username, email, COALESCE(avatar_url, ''), status, created_at
	FROM users
	WHERE LOWER(username) = LOWER($1) OR LOWER(email) = LOWER($1) OR id = $1
	LIMIT 1`

	u := &models.User{}
	err := r.db.QueryRow(q, query).Scan(
		&u.ID,
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
	SELECT id, username, email, COALESCE(avatar_url, ''), status, created_at
	FROM users
	WHERE LOWER(username) LIKE LOWER($1) OR LOWER(email) LIKE LOWER($1)
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


