package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gorilla/mux"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/websocket"
)

func setupTestServerHandler() (*ServerHandler, *repository.MemoryRepository) {
	repo := repository.NewMemoryRepository()
	hub := websocket.NewHub(nil)
	handler := NewServerHandler(repo, hub)
	return handler, repo
}

func newAuthRequest(method, url string, body []byte, userID string, vars map[string]string) *http.Request {
	var req *http.Request
	if body != nil {
		req = httptest.NewRequest(method, url, bytes.NewReader(body))
	} else {
		req = httptest.NewRequest(method, url, nil)
	}
	if userID != "" {
		ctx := context.WithValue(req.Context(), "user_id", userID)
		req = req.WithContext(ctx)
	}
	if vars != nil {
		req = mux.SetURLVars(req, vars)
	}
	return req
}

func TestServerHandler_CreateInvite(t *testing.T) {
	handler, _ := setupTestServerHandler()

	maxAge := 3600
	maxUses := 5
	reqBody, _ := json.Marshal(models.CreateInviteRequest{
		MaxAgeSeconds: &maxAge,
		MaxUses:       &maxUses,
	})

	// 1. Success case
	req := newAuthRequest("POST", "/api/servers/1/invites", reqBody, "usr_dev_1", map[string]string{"id": "1"})
	rr := httptest.NewRecorder()
	handler.CreateInvite(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("Expected status 201 Created, got %d: %s", rr.Code, rr.Body.String())
	}

	var invite models.ServerInvite
	if err := json.NewDecoder(rr.Body).Decode(&invite); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}
	if len(invite.Code) != 7 {
		t.Errorf("Expected 7-character invite code, got: %s", invite.Code)
	}
	if invite.MaxUses != 5 {
		t.Errorf("Expected MaxUses 5, got %d", invite.MaxUses)
	}

	// 2. Unauthorized case (missing user_id)
	unauthReq := newAuthRequest("POST", "/api/servers/1/invites", reqBody, "", map[string]string{"id": "1"})
	unauthRR := httptest.NewRecorder()
	handler.CreateInvite(unauthRR, unauthReq)

	if unauthRR.Code != http.StatusUnauthorized {
		t.Errorf("Expected status 401 Unauthorized, got %d", unauthRR.Code)
	}

	// 3. Non-existent server
	notFoundReq := newAuthRequest("POST", "/api/servers/srv_not_found/invites", reqBody, "usr_dev_1", map[string]string{"id": "srv_not_found"})
	notFoundRR := httptest.NewRecorder()
	handler.CreateInvite(notFoundRR, notFoundReq)

	if notFoundRR.Code != http.StatusNotFound {
		t.Errorf("Expected status 404 Not Found, got %d", notFoundRR.Code)
	}
}

func TestServerHandler_ListInvites(t *testing.T) {
	handler, repo := setupTestServerHandler()

	_ = repo.CreateInvite(&models.ServerInvite{
		Code:      "list123",
		ServerID:  "1",
		CreatorID: "usr_dev_1",
	})

	req := newAuthRequest("GET", "/api/servers/1/invites", nil, "usr_dev_1", map[string]string{"id": "1"})
	rr := httptest.NewRecorder()

	handler.ListInvites(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected status 200 OK, got %d", rr.Code)
	}

	var invites []*models.ServerInvite
	if err := json.NewDecoder(rr.Body).Decode(&invites); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}
	if len(invites) == 0 {
		t.Errorf("Expected at least 1 invite in list")
	}
}

func TestServerHandler_DeleteInvite(t *testing.T) {
	handler, repo := setupTestServerHandler()

	_ = repo.CreateInvite(&models.ServerInvite{
		Code:      "del1234",
		ServerID:  "1",
		CreatorID: "usr_dev_1",
	})

	// 1. Forbidden for unauthorized user
	reqForbidden := newAuthRequest("DELETE", "/api/servers/1/invites/del1234", nil, "usr_dev_2", map[string]string{"code": "del1234"})
	rrForbidden := httptest.NewRecorder()
	handler.DeleteInvite(rrForbidden, reqForbidden)

	if rrForbidden.Code != http.StatusForbidden {
		t.Errorf("Expected status 403 Forbidden, got %d", rrForbidden.Code)
	}

	// 2. Success for creator
	reqSuccess := newAuthRequest("DELETE", "/api/servers/1/invites/del1234", nil, "usr_dev_1", map[string]string{"code": "del1234"})
	rrSuccess := httptest.NewRecorder()
	handler.DeleteInvite(rrSuccess, reqSuccess)

	if rrSuccess.Code != http.StatusNoContent {
		t.Errorf("Expected status 204 NoContent, got %d", rrSuccess.Code)
	}
}

func TestServerHandler_JoinServer_InviteCases(t *testing.T) {
	handler, repo := setupTestServerHandler()

	// Setup active invite
	_ = repo.CreateInvite(&models.ServerInvite{
		Code:      "join123",
		ServerID:  "1",
		CreatorID: "usr_dev_1",
		MaxUses:   1,
	})

	// Setup expired invite
	past := time.Now().Add(-5 * time.Minute)
	_ = repo.CreateInvite(&models.ServerInvite{
		Code:      "exp1234",
		ServerID:  "1",
		CreatorID: "usr_dev_1",
		ExpiresAt: &past,
	})

	// 1. Join with valid code
	reqJoin := newAuthRequest("POST", "/api/servers/join/join123", nil, "usr_dev_2", map[string]string{"code": "join123"})
	rrJoin := httptest.NewRecorder()
	handler.JoinServer(rrJoin, reqJoin)

	if rrJoin.Code != http.StatusOK {
		t.Fatalf("Expected status 200 OK joining with invite code, got %d: %s", rrJoin.Code, rrJoin.Body.String())
	}

	// 2. Join again with now-exhausted code (max_uses was 1)
	reqExhausted := newAuthRequest("POST", "/api/servers/join/join123", nil, "usr_dev_2", map[string]string{"code": "join123"})
	rrExhausted := httptest.NewRecorder()
	handler.JoinServer(rrExhausted, reqExhausted)

	if rrExhausted.Code != http.StatusBadRequest {
		t.Errorf("Expected status 400 Bad Request for exhausted invite, got %d", rrExhausted.Code)
	}

	// 3. Join with expired invite
	reqExp := newAuthRequest("POST", "/api/servers/join/exp1234", nil, "usr_dev_2", map[string]string{"code": "exp1234"})
	rrExp := httptest.NewRecorder()
	handler.JoinServer(rrExp, reqExp)

	if rrExp.Code != http.StatusBadRequest {
		t.Errorf("Expected status 400 Bad Request for expired invite, got %d", rrExp.Code)
	}

	// 4. Fallback: Join with direct ServerID
	reqFallback := newAuthRequest("POST", "/api/servers/join/1", nil, "usr_dev_2", map[string]string{"code": "1"})
	rrFallback := httptest.NewRecorder()
	handler.JoinServer(rrFallback, reqFallback)

	if rrFallback.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK with server ID fallback, got %d: %s", rrFallback.Code, rrFallback.Body.String())
	}

	// 5. Join with non-existent code/server
	reqNotFound := newAuthRequest("POST", "/api/servers/join/nonexistent", nil, "usr_dev_2", map[string]string{"code": "nonexistent"})
	rrNotFound := httptest.NewRecorder()
	handler.JoinServer(rrNotFound, reqNotFound)
	if rrNotFound.Code != http.StatusNotFound {
		t.Errorf("Expected status 404 Not Found for non-existent code, got %d", rrNotFound.Code)
	}

	// 6. Join unauthorized
	reqUnauth := newAuthRequest("POST", "/api/servers/join/1", nil, "", map[string]string{"code": "1"})
	rrUnauth := httptest.NewRecorder()
	handler.JoinServer(rrUnauth, reqUnauth)
	if rrUnauth.Code != http.StatusUnauthorized {
		t.Errorf("Expected status 401 Unauthorized, got %d", rrUnauth.Code)
	}
}

func TestServerHandler_MembersManagement(t *testing.T) {
	handler, repo := setupTestServerHandler()

	// 1. List members
	reqList := newAuthRequest("GET", "/api/servers/1/members", nil, "usr_dev_1", map[string]string{"id": "1"})
	rrList := httptest.NewRecorder()
	handler.ListMembers(rrList, reqList)
	if rrList.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for ListMembers, got %d", rrList.Code)
	}

	// List members for non-existent server
	reqListNF := newAuthRequest("GET", "/api/servers/999/members", nil, "usr_dev_1", map[string]string{"id": "999"})
	rrListNF := httptest.NewRecorder()
	handler.ListMembers(rrListNF, reqListNF)
	if rrListNF.Code != http.StatusNotFound {
		t.Errorf("Expected status 404 Not Found for ListMembers on invalid server, got %d", rrListNF.Code)
	}

	// 2. Add member by username (success)
	repo.CreateUser(&models.User{
		ID:       "usr_gamer",
		Username: "dev_gamer",
		Email:    "gamer@projectnbx.com",
	})
	addReqBody, _ := json.Marshal(map[string]string{"username": "dev_gamer"})
	reqAdd := newAuthRequest("POST", "/api/servers/1/members", addReqBody, "usr_dev_1", map[string]string{"id": "1"})
	rrAdd := httptest.NewRecorder()
	handler.AddMember(rrAdd, reqAdd)
	if rrAdd.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for AddMember, got %d: %s", rrAdd.Code, rrAdd.Body.String())
	}

	// Add member by email (success)
	addEmailBody, _ := json.Marshal(map[string]string{"email": "dev@nbx.com"})
	reqAddEmail := newAuthRequest("POST", "/api/servers/1/members", addEmailBody, "usr_dev_1", map[string]string{"id": "1"})
	rrAddEmail := httptest.NewRecorder()
	handler.AddMember(rrAddEmail, reqAddEmail)
	if rrAddEmail.Code != http.StatusOK {
		t.Errorf("Expected status 200 OK for AddMember by email, got %d", rrAddEmail.Code)
	}

	// Add member forbidden (non-owner)
	reqAddForb := newAuthRequest("POST", "/api/servers/1/members", addReqBody, "usr_dev_2", map[string]string{"id": "1"})
	rrAddForb := httptest.NewRecorder()
	handler.AddMember(rrAddForb, reqAddForb)
	if rrAddForb.Code != http.StatusForbidden {
		t.Errorf("Expected status 403 Forbidden for AddMember by non-owner, got %d", rrAddForb.Code)
	}

	// Add member with non-existent user
	addNotFoundBody, _ := json.Marshal(map[string]string{"username": "non_existent_user_999"})
	reqAddNF := newAuthRequest("POST", "/api/servers/1/members", addNotFoundBody, "usr_dev_1", map[string]string{"id": "1"})
	rrAddNF := httptest.NewRecorder()
	handler.AddMember(rrAddNF, reqAddNF)
	if rrAddNF.Code != http.StatusNotFound {
		t.Errorf("Expected status 404 Not Found for AddMember non-existent user, got %d", rrAddNF.Code)
	}

	// 3. Remove member (forbidden for random user)
	reqRemForb := newAuthRequest("DELETE", "/api/servers/1/members/usr_dev_2", nil, "usr_dev_3", map[string]string{"id": "1", "userId": "usr_dev_2"})
	rrRemForb := httptest.NewRecorder()
	handler.RemoveMember(rrRemForb, reqRemForb)
	if rrRemForb.Code != http.StatusForbidden {
		t.Errorf("Expected status 403 Forbidden for RemoveMember, got %d", rrRemForb.Code)
	}

	// Remove member (success by owner)
	_ = repo.AddServerMember("1", "usr_dev_2")
	reqRemSuccess := newAuthRequest("DELETE", "/api/servers/1/members/usr_dev_2", nil, "usr_dev_1", map[string]string{"id": "1", "userId": "usr_dev_2"})
	rrRemSuccess := httptest.NewRecorder()
	handler.RemoveMember(rrRemSuccess, reqRemSuccess)
	if rrRemSuccess.Code != http.StatusNoContent {
		t.Errorf("Expected status 204 NoContent for RemoveMember by owner, got %d", rrRemSuccess.Code)
	}
}

