package repository

import (
	"testing"
	"time"

	"github.com/projectnbx/backend/internal/models"
)

func TestMemoryRepository_Users(t *testing.T) {
	repo := NewMemoryRepository()

	// Initial seed users exist
	admin, err := repo.GetUserByID("usr_dev_1")
	if err != nil || admin == nil {
		t.Fatalf("Expected seed admin user, got err: %v", err)
	}

	// Create User
	newUser := &models.User{
		ID:        "usr_new_1",
		Username:  "NewGamer",
		Email:     "newgamer@test.com",
		Password:  "hashed_pass",
		Status:    "online",
		CreatedAt: time.Now(),
	}
	err = repo.CreateUser(newUser)
	if err != nil {
		t.Fatalf("CreateUser failed: %v", err)
	}

	// Duplicate email
	dupUser := &models.User{
		ID:       "usr_new_2",
		Username: "OtherGamer",
		Email:    "newgamer@test.com",
	}
	err = repo.CreateUser(dupUser)
	if err != ErrAlreadyExists {
		t.Errorf("Expected ErrAlreadyExists for duplicate email, got: %v", err)
	}

	// GetUserByEmail
	byEmail, err := repo.GetUserByEmail("newgamer@test.com")
	if err != nil || byEmail.ID != newUser.ID {
		t.Errorf("GetUserByEmail failed or mismatch: %v", err)
	}

	// Non-existent user
	_, err = repo.GetUserByID("usr_non_existent")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound, got: %v", err)
	}
	_, err = repo.GetUserByEmail("none@test.com")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound for non-existent email, got: %v", err)
	}

	// UpdateUserStatus
	err = repo.UpdateUserStatus("usr_new_1", "offline")
	if err != nil {
		t.Errorf("UpdateUserStatus failed: %v", err)
	}
	updated, _ := repo.GetUserByID("usr_new_1")
	if updated.Status != "offline" {
		t.Errorf("Expected status offline, got %s", updated.Status)
	}

	// Update non-existent user status
	err = repo.UpdateUserStatus("usr_non_existent", "dnd")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound on updating status of missing user, got %v", err)
	}

	// FindUser & SearchUsers
	found, err := repo.FindUser("NewGamer")
	if err != nil || found.ID != newUser.ID {
		t.Errorf("FindUser failed: %v", err)
	}
	_, err = repo.FindUser("NotFoundName")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound, got: %v", err)
	}

	users, err := repo.SearchUsers("Gamer", 5)
	if err != nil || len(users) == 0 {
		t.Errorf("SearchUsers failed, got %d users", len(users))
	}
}

func TestMemoryRepository_ServersAndChannels(t *testing.T) {
	repo := NewMemoryRepository()

	servers, err := repo.ListServers()
	if err != nil {
		t.Fatalf("ListServers failed: %v", err)
	}
	if len(servers) == 0 {
		t.Fatal("Expected initial seed servers")
	}

	// Create Server
	newServer := &models.Server{
		ID:          "srv_custom_1",
		Name:        "Custom Hub",
		IconURL:     "https://example.com/icon.png",
		OwnerID:     "usr_dev_1",
	}
	err = repo.CreateServer(newServer)
	if err != nil {
		t.Fatalf("CreateServer failed: %v", err)
	}

	fetchedServer, err := repo.GetServerByID("srv_custom_1")
	if err != nil || fetchedServer.Name != "Custom Hub" {
		t.Errorf("GetServerByID failed: %v", err)
	}

	_, err = repo.GetServerByID("srv_missing")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound for missing server, got: %v", err)
	}

	// Channels
	seedChannels, err := repo.ListChannelsByServer("1")
	if err != nil || len(seedChannels) == 0 {
		t.Fatalf("ListChannelsByServer failed or empty for server 1: %v", err)
	}

	newChan := &models.Channel{
		ID:       "chan_custom_1",
		ServerID: "srv_custom_1",
		Name:     "gaming",
		Type:     "text",
	}
	err = repo.CreateChannel(newChan)
	if err != nil {
		t.Fatalf("CreateChannel failed: %v", err)
	}

	fetchedChan, err := repo.GetChannelByID("chan_custom_1")
	if err != nil || fetchedChan.Name != "gaming" {
		t.Errorf("GetChannelByID failed: %v", err)
	}

	_, err = repo.GetChannelByID("chan_missing")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound for missing channel, got: %v", err)
	}
}

func TestMemoryRepository_Messages(t *testing.T) {
	repo := NewMemoryRepository()

	msg := &models.Message{
		ID:        "msg_101",
		ChannelID: "c1",
		AuthorID:  "usr_dev_1",
		Content:   "Hello World!",
		CreatedAt: time.Now(),
	}

	err := repo.CreateMessage(msg)
	if err != nil {
		t.Fatalf("CreateMessage failed: %v", err)
	}

	fetched, err := repo.GetMessageByID("msg_101")
	if err != nil || fetched.Content != "Hello World!" {
		t.Fatalf("GetMessageByID failed: %v", err)
	}

	_, err = repo.GetMessageByID("msg_missing")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound for missing message, got: %v", err)
	}

	// Update Message
	err = repo.UpdateMessage("msg_101", "Updated Content!")
	if err != nil {
		t.Fatalf("UpdateMessage failed: %v", err)
	}
	updated, _ := repo.GetMessageByID("msg_101")
	if updated.Content != "Updated Content!" {
		t.Errorf("Expected updated content, got %s", updated.Content)
	}

	err = repo.UpdateMessage("msg_missing", "content")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound on updating missing message, got: %v", err)
	}

	// List Messages
	msgs, err := repo.ListMessagesByChannel("c1", 10)
	if err != nil || len(msgs) == 0 {
		t.Errorf("ListMessagesByChannel failed: %v", err)
	}

	// Delete Message
	err = repo.DeleteMessage("msg_101")
	if err != nil {
		t.Fatalf("DeleteMessage failed: %v", err)
	}
	_, err = repo.GetMessageByID("msg_101")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound after delete, got: %v", err)
	}

	err = repo.DeleteMessage("msg_missing")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound on deleting missing message, got: %v", err)
	}
}

func TestMemoryRepository_AuditLogs(t *testing.T) {
	repo := NewMemoryRepository()

	uid := "usr_dev_1"
	log := &models.AuditLog{
		ID:        "audit_1",
		UserID:    &uid,
		Action:    "LOGIN",
		Source:    models.AuditSourceAuth,
		Metadata:  map[string]interface{}{"ip": "127.0.0.1"},
		CreatedAt: time.Now(),
	}

	err := repo.CreateAuditLog(log)
	if err != nil {
		t.Fatalf("CreateAuditLog failed: %v", err)
	}

	_, err = repo.ListAuditLogs(10, models.AuditSourceAuth)
	if err != nil {
		t.Fatalf("ListAuditLogs failed: %v", err)
	}

	_, err = repo.ListAuditLogs(10, "")
	if err != nil {
		t.Errorf("ListAuditLogs without source filter failed: %v", err)
	}
}

func TestMemoryRepository_Members(t *testing.T) {
	repo := NewMemoryRepository()

	// Server 1
	err := repo.AddServerMember("1", "usr_dev_2")
	if err != nil {
		t.Fatalf("AddServerMember failed: %v", err)
	}

	members, err := repo.ListServerMembers("1")
	if err != nil || len(members) == 0 {
		t.Fatalf("ListServerMembers failed: %v", err)
	}

	// IsServerMember tests
	// 1. Owner
	srv, _ := repo.GetServerByID("1")
	isOwnerMember, err := repo.IsServerMember("1", srv.OwnerID)
	if err != nil || !isOwnerMember {
		t.Errorf("Expected owner to be server member: %v", err)
	}

	// 2. Added member
	isMember, err := repo.IsServerMember("1", "usr_dev_2")
	if err != nil || !isMember {
		t.Errorf("Expected added member to be server member: %v", err)
	}

	// Remove member
	err = repo.RemoveServerMember("1", "usr_dev_2")
	if err != nil {
		t.Fatalf("RemoveServerMember failed: %v", err)
	}

	// 3. Removed/non-member
	isMemberAfterRemove, err := repo.IsServerMember("1", "usr_dev_2")
	if err != nil || isMemberAfterRemove {
		t.Errorf("Expected false for removed member, got %v (err: %v)", isMemberAfterRemove, err)
	}

	// 4. Missing server
	_, err = repo.IsServerMember("9999", "usr_dev_1")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound for IsServerMember with missing server, got %v", err)
	}

	// Server not found for members
	_, err = repo.ListServerMembers("9999")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound for non-existent server, got: %v", err)
	}
}
