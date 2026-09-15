package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/projectnbx/backend/internal/models"
)

func TestServerHandler_CRUD(t *testing.T) {
	handler, _ := setupTestServerHandler()

	// 1. ListServers
	reqList := newAuthRequest("GET", "/api/servers", nil, "usr_dev_1", nil)
	rrList := httptest.NewRecorder()
	handler.ListServers(rrList, reqList)

	if rrList.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for ListServers, got %d", rrList.Code)
	}

	// 2. CreateServer
	srvBody, _ := json.Marshal(models.CreateServerRequest{
		Name:    "Test Server Alpha",
		IconURL: "https://example.com/icon.png",
	})
	reqCreate := newAuthRequest("POST", "/api/servers", srvBody, "usr_dev_1", nil)
	rrCreate := httptest.NewRecorder()
	handler.CreateServer(rrCreate, reqCreate)

	if rrCreate.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created for CreateServer, got %d: %s", rrCreate.Code, rrCreate.Body.String())
	}

	var createdServer models.Server
	_ = json.NewDecoder(rrCreate.Body).Decode(&createdServer)

	// 3. GetServer
	reqGet := newAuthRequest("GET", "/api/servers/"+createdServer.ID, nil, "usr_dev_1", map[string]string{"id": createdServer.ID})
	rrGet := httptest.NewRecorder()
	handler.GetServer(rrGet, reqGet)

	if rrGet.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for GetServer, got %d", rrGet.Code)
	}

	// Missing server
	reqMissing := newAuthRequest("GET", "/api/servers/missing_999", nil, "usr_dev_1", map[string]string{"id": "missing_999"})
	rrMissing := httptest.NewRecorder()
	handler.GetServer(rrMissing, reqMissing)

	if rrMissing.Code != http.StatusNotFound {
		t.Errorf("Expected 404 Not Found, got %d", rrMissing.Code)
	}
}

func TestServerHandler_ChannelsAndMessages(t *testing.T) {
	handler, repo := setupTestServerHandler()

	// 1. ListChannels
	reqListChan := newAuthRequest("GET", "/api/servers/1/channels", nil, "usr_dev_1", map[string]string{"id": "1"})
	rrListChan := httptest.NewRecorder()
	handler.ListChannels(rrListChan, reqListChan)

	if rrListChan.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for ListChannels, got %d", rrListChan.Code)
	}

	// 2. CreateChannel
	chanBody, _ := json.Marshal(models.CreateChannelRequest{
		Name: "dev-chat",
		Type: "text",
	})
	reqCreateChan := newAuthRequest("POST", "/api/servers/1/channels", chanBody, "usr_dev_1", map[string]string{"id": "1"})
	rrCreateChan := httptest.NewRecorder()
	handler.CreateChannel(rrCreateChan, reqCreateChan)

	if rrCreateChan.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created for CreateChannel, got %d: %s", rrCreateChan.Code, rrCreateChan.Body.String())
	}

	var createdChan models.Channel
	_ = json.NewDecoder(rrCreateChan.Body).Decode(&createdChan)

	// 3. ListMessages
	reqListMsg := newAuthRequest("GET", "/api/channels/"+createdChan.ID+"/messages", nil, "usr_dev_1", map[string]string{"id": createdChan.ID})
	rrListMsg := httptest.NewRecorder()
	handler.ListMessages(rrListMsg, reqListMsg)

	if rrListMsg.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for ListMessages, got %d", rrListMsg.Code)
	}

	// 4. Create Message via repo and test UpdateMessage & DeleteMessage
	msg := &models.Message{
		ID:        "msg_test_1",
		ChannelID: createdChan.ID,
		ServerID:  "1",
		AuthorID:  "usr_dev_1",
		Content:   "Original Content",
	}
	_ = repo.CreateMessage(msg)

	updateBody, _ := json.Marshal(models.UpdateMessageRequest{Content: "Edited Content"})
	reqUpdate := newAuthRequest("PUT", "/api/servers/1/channels/"+createdChan.ID+"/messages/msg_test_1", updateBody, "usr_dev_1", map[string]string{
		"id":        "1",
		"channelId": createdChan.ID,
		"messageId": "msg_test_1",
	})
	rrUpdate := httptest.NewRecorder()
	handler.UpdateMessage(rrUpdate, reqUpdate)

	if rrUpdate.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for UpdateMessage, got %d: %s", rrUpdate.Code, rrUpdate.Body.String())
	}

	// DeleteMessage
	reqDelete := newAuthRequest("DELETE", "/api/servers/1/channels/"+createdChan.ID+"/messages/msg_test_1", nil, "usr_dev_1", map[string]string{
		"id":        "1",
		"channelId": createdChan.ID,
		"messageId": "msg_test_1",
	})
	rrDelete := httptest.NewRecorder()
	handler.DeleteMessage(rrDelete, reqDelete)

	if rrDelete.Code != http.StatusNoContent {
		t.Errorf("Expected 204 No Content for DeleteMessage, got %d", rrDelete.Code)
	}
}

func TestServerHandler_RemoveMember(t *testing.T) {
	handler, repo := setupTestServerHandler()

	// Add member first
	_ = repo.AddServerMember("1", "usr_dev_2")

	// 1. Success removing by owner
	reqRem := newAuthRequest("DELETE", "/api/servers/1/members/usr_dev_2", nil, "usr_dev_1", map[string]string{"id": "1", "userId": "usr_dev_2"})
	rrRem := httptest.NewRecorder()
	handler.RemoveMember(rrRem, reqRem)

	if rrRem.Code != http.StatusNoContent {
		t.Errorf("Expected 204 No Content for RemoveMember, got %d", rrRem.Code)
	}

	// 2. Server not found
	reqRemNF := newAuthRequest("DELETE", "/api/servers/999/members/usr_dev_2", nil, "usr_dev_1", map[string]string{"id": "999", "userId": "usr_dev_2"})
	rrRemNF := httptest.NewRecorder()
	handler.RemoveMember(rrRemNF, reqRemNF)

	if rrRemNF.Code != http.StatusNotFound {
		t.Errorf("Expected 404 Not Found for missing server, got %d", rrRemNF.Code)
	}
}
