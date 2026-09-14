package repository

import (
	"testing"
	"time"

	"github.com/projectnbx/backend/internal/models"
)

func TestMemoryRepo_Invites(t *testing.T) {
	repo := NewMemoryRepository()

	// 1. Test CreateInvite and GetInviteByCode
	expiresIn1h := time.Now().Add(1 * time.Hour)
	invite := &models.ServerInvite{
		Code:      "abc1234",
		ServerID:  "1",
		CreatorID: "usr_dev_1",
		MaxUses:   2,
		UsesCount: 0,
		ExpiresAt: &expiresIn1h,
	}

	err := repo.CreateInvite(invite)
	if err != nil {
		t.Fatalf("CreateInvite failed: %v", err)
	}

	retrieved, err := repo.GetInviteByCode("abc1234")
	if err != nil {
		t.Fatalf("GetInviteByCode failed: %v", err)
	}
	if retrieved.Code != "abc1234" || retrieved.IsExpired || retrieved.IsExhausted {
		t.Errorf("Unexpected invite state: %+v", retrieved)
	}
	if retrieved.Creator == nil || retrieved.Creator.Username == "" {
		t.Errorf("Expected creator user populated, got nil or empty")
	}

	// 2. Test IncrementInviteUses up to limit
	err = repo.IncrementInviteUses("abc1234")
	if err != nil {
		t.Fatalf("First IncrementInviteUses failed: %v", err)
	}

	err = repo.IncrementInviteUses("abc1234")
	if err != nil {
		t.Fatalf("Second IncrementInviteUses failed: %v", err)
	}

	retrieved, err = repo.GetInviteByCode("abc1234")
	if err != nil {
		t.Fatalf("GetInviteByCode failed: %v", err)
	}
	if !retrieved.IsExhausted {
		t.Errorf("Expected invite to be exhausted after 2 uses, got %v", retrieved.IsExhausted)
	}

	// 3. Exceeding max uses should return ErrMaxUsesReached
	err = repo.IncrementInviteUses("abc1234")
	if err != ErrMaxUsesReached {
		t.Errorf("Expected ErrMaxUsesReached, got: %v", err)
	}

	// 4. Test expired invite
	expiredTime := time.Now().Add(-1 * time.Minute)
	expiredInvite := &models.ServerInvite{
		Code:      "expired1",
		ServerID:  "1",
		CreatorID: "usr_dev_1",
		ExpiresAt: &expiredTime,
	}
	if err := repo.CreateInvite(expiredInvite); err != nil {
		t.Fatalf("CreateInvite expired failed: %v", err)
	}

	retrievedExpired, err := repo.GetInviteByCode("expired1")
	if err != nil {
		t.Fatalf("GetInviteByCode expired failed: %v", err)
	}
	if !retrievedExpired.IsExpired {
		t.Errorf("Expected invite to be marked expired")
	}

	// 5. Test ListServerInvites
	invites, err := repo.ListServerInvites("1")
	if err != nil {
		t.Fatalf("ListServerInvites failed: %v", err)
	}
	if len(invites) < 2 {
		t.Errorf("Expected at least 2 invites for srv_1, got %d", len(invites))
	}

	// 6. Test DeleteInvite
	err = repo.DeleteInvite("abc1234")
	if err != nil {
		t.Fatalf("DeleteInvite failed: %v", err)
	}

	_, err = repo.GetInviteByCode("abc1234")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound after delete, got %v", err)
	}

	// 7. Increment on non-existent invite
	err = repo.IncrementInviteUses("non_existent")
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound for incrementing non_existent, got %v", err)
	}
}
