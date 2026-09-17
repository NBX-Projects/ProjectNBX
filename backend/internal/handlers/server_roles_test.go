package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/projectnbx/backend/internal/models"
)

func TestServerHandler_PublicServersAndJoinRequests(t *testing.T) {
	handler, repo := setupTestServerHandler()

	// 1. List Public Servers
	req := newAuthRequest("GET", "/api/servers/public", nil, "usr_dev_2", nil)
	rr := httptest.NewRecorder()
	handler.ListPublicServers(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d: %s", rr.Code, rr.Body.String())
	}

	var publicServers []*models.PublicServerDTO
	if err := json.Unmarshal(rr.Body.Bytes(), &publicServers); err != nil {
		t.Fatalf("Failed to decode public servers: %v", err)
	}

	if len(publicServers) == 0 {
		t.Fatalf("Expected at least 1 public server in seed data")
	}

	// 2. Submit Join Request for public server (ID "1")
	joinReqBody, _ := json.Marshal(map[string]string{
		"message": "Gostaria de participar da guilda!",
	})
	req = newAuthRequest("POST", "/api/servers/1/join-requests", joinReqBody, "usr_dev_2", map[string]string{"id": "1"})
	rr = httptest.NewRecorder()
	handler.CreateJoinRequest(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created for join request, got %d: %s", rr.Code, rr.Body.String())
	}

	var createdJoinReq models.ServerJoinRequest
	_ = json.Unmarshal(rr.Body.Bytes(), &createdJoinReq)
	if createdJoinReq.Status != "pending" {
		t.Fatalf("Expected status 'pending', got '%s'", createdJoinReq.Status)
	}

	// 3. List Join Requests as Server Owner (usr_dev_1)
	req = newAuthRequest("GET", "/api/servers/1/join-requests", nil, "usr_dev_1", map[string]string{"id": "1"})
	rr = httptest.NewRecorder()
	handler.ListJoinRequests(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for list join requests, got %d: %s", rr.Code, rr.Body.String())
	}

	var joinRequests []*models.ServerJoinRequest
	_ = json.Unmarshal(rr.Body.Bytes(), &joinRequests)
	if len(joinRequests) != 1 {
		t.Fatalf("Expected 1 join request, got %d", len(joinRequests))
	}

	// 4. Review Join Request (Approve)
	reviewBody, _ := json.Marshal(map[string]string{
		"status": "approved",
	})
	req = newAuthRequest("POST", "/api/servers/1/join-requests/"+createdJoinReq.ID+"/review", reviewBody, "usr_dev_1", map[string]string{
		"id":        "1",
		"requestId": createdJoinReq.ID,
	})
	rr = httptest.NewRecorder()
	handler.ReviewJoinRequest(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for review join request, got %d: %s", rr.Code, rr.Body.String())
	}

	// Verify usr_dev_2 is now a member
	isMember, _ := repo.IsServerMember("1", "usr_dev_2")
	if !isMember {
		t.Fatalf("Expected usr_dev_2 to be a member after approved join request")
	}
}

func TestServerHandler_RolesAndPermissions(t *testing.T) {
	handler, repo := setupTestServerHandler()

	// 1. Create Role as Server Owner (usr_dev_1)
	roleReqBody, _ := json.Marshal(models.CreateRoleRequest{
		Name:     "Moderador",
		Color:    4294334375, // #F5CBA7
		Position: 1,
		Permissions: map[string]bool{
			"can_accept_join_requests": true,
			"can_manage_roles":         false,
		},
	})
	req := newAuthRequest("POST", "/api/servers/1/roles", roleReqBody, "usr_dev_1", map[string]string{"id": "1"})
	rr := httptest.NewRecorder()
	handler.CreateRole(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created for role, got %d: %s", rr.Code, rr.Body.String())
	}

	var createdRole models.ServerRole
	_ = json.Unmarshal(rr.Body.Bytes(), &createdRole)
	if createdRole.Name != "Moderador" {
		t.Fatalf("Expected role name 'Moderador', got '%s'", createdRole.Name)
	}

	// 2. List Roles
	req = newAuthRequest("GET", "/api/servers/1/roles", nil, "usr_dev_1", map[string]string{"id": "1"})
	rr = httptest.NewRecorder()
	handler.ListRoles(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for list roles, got %d", rr.Code)
	}

	// 3. Assign Role to Member (usr_dev_2)
	_ = repo.AddServerMember("1", "usr_dev_2")
	req = newAuthRequest("POST", "/api/servers/1/members/usr_dev_2/roles/"+createdRole.ID, nil, "usr_dev_1", map[string]string{
		"id":     "1",
		"userId": "usr_dev_2",
		"roleId": createdRole.ID,
	})
	rr = httptest.NewRecorder()
	handler.AssignMemberRole(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for role assignment, got %d: %s", rr.Code, rr.Body.String())
	}

	// 4. Verify HasServerPermission for usr_dev_2
	hasPerm, err := repo.HasServerPermission("1", "usr_dev_2", "can_accept_join_requests")
	if err != nil || !hasPerm {
		t.Fatalf("Expected usr_dev_2 to have 'can_accept_join_requests' permission")
	}

	hasManageRoles, _ := repo.HasServerPermission("1", "usr_dev_2", "can_manage_roles")
	if hasManageRoles {
		t.Fatalf("Expected usr_dev_2 to NOT have 'can_manage_roles' permission")
	}

	// 5. Remove Role
	req = newAuthRequest("DELETE", "/api/servers/1/members/usr_dev_2/roles/"+createdRole.ID, nil, "usr_dev_1", map[string]string{
		"id":     "1",
		"userId": "usr_dev_2",
		"roleId": createdRole.ID,
	})
	rr = httptest.NewRecorder()
	handler.RemoveMemberRole(rr, req)

	if rr.Code != http.StatusNoContent {
		t.Fatalf("Expected 204 No Content for remove member role, got %d", rr.Code)
	}

	hasPermAfter, _ := repo.HasServerPermission("1", "usr_dev_2", "can_accept_join_requests")
	if hasPermAfter {
		t.Fatalf("Expected usr_dev_2 to lose permission after role removed")
	}
}
