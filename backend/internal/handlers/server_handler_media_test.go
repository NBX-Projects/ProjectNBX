package handlers

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/storage"
	"github.com/projectnbx/backend/internal/websocket"
)

func setupMediaDeleteTest(t *testing.T) (*ServerHandler, *repository.MemoryRepository, string) {
	t.Helper()
	dir := t.TempDir()
	repo := repository.NewMemoryRepository()
	handler := NewServerHandler(repo, websocket.NewHub(nil), storage.NewLocalStorageService(dir, "http://localhost:8080"))
	return handler, repo, dir
}

func writeUploadFile(t *testing.T, dir, name string) string {
	t.Helper()
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte("img"), 0o644); err != nil {
		t.Fatalf("Falha ao criar arquivo de teste: %v", err)
	}
	return path
}

func deleteMessageAs(handler *ServerHandler, userID, messageID string) *httptest.ResponseRecorder {
	req := newAuthRequest("DELETE", "/api/servers/1/channels/t1/messages/"+messageID, nil, userID, map[string]string{
		"id":        "1",
		"channelId": "t1",
		"messageId": messageID,
	})
	rr := httptest.NewRecorder()
	handler.DeleteMessage(rr, req)
	return rr
}

// A remoção roda em goroutine: casos positivos esperam mais, negativos só o suficiente para detectar regressão
const (
	removalTimeout   = 2 * time.Second
	noRemovalTimeout = 200 * time.Millisecond
)

func waitForRemoval(path string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			return true
		}
		time.Sleep(10 * time.Millisecond)
	}
	return false
}

func TestDeleteMessage_RemovesAuthorOwnedMedia(t *testing.T) {
	handler, repo, dir := setupMediaDeleteTest(t)
	filePath := writeUploadFile(t, dir, "img_own.png")
	mediaURL := "http://localhost:8080/uploads/img_own.png"

	_ = repo.CreateMediaUpload(&models.MediaUpload{URL: mediaURL, OwnerID: "usr_dev_1", MediaType: "image/png"})
	_ = repo.CreateMessage(&models.Message{ID: "msg_media_own", ChannelID: "t1", ServerID: "1", AuthorID: "usr_dev_1", MediaURL: mediaURL})

	if rr := deleteMessageAs(handler, "usr_dev_1", "msg_media_own"); rr.Code != http.StatusNoContent {
		t.Fatalf("Esperava 204, obteve %d: %s", rr.Code, rr.Body.String())
	}

	if !waitForRemoval(filePath, removalTimeout) {
		t.Error("Arquivo do autor deveria ter sido removido do storage")
	}
	deadline := time.Now().Add(removalTimeout)
	for time.Now().Before(deadline) {
		if _, err := repo.GetMediaUploadByURL(mediaURL); err == repository.ErrNotFound {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Error("Registro de upload deveria ter sido removido")
}

func TestDeleteMessage_KeepsMediaOwnedByAnotherUser(t *testing.T) {
	handler, repo, dir := setupMediaDeleteTest(t)
	filePath := writeUploadFile(t, dir, "img_victim.png")
	victimURL := "http://localhost:8080/uploads/img_victim.png"

	// Mensagem forjada: o atacante referencia a mídia de outro usuário
	_ = repo.CreateMediaUpload(&models.MediaUpload{URL: victimURL, OwnerID: "usr_victim", MediaType: "image/png"})
	_ = repo.CreateMessage(&models.Message{ID: "msg_forged", ChannelID: "t1", ServerID: "1", AuthorID: "usr_dev_1", MediaURL: victimURL})

	if rr := deleteMessageAs(handler, "usr_dev_1", "msg_forged"); rr.Code != http.StatusNoContent {
		t.Fatalf("Esperava 204, obteve %d: %s", rr.Code, rr.Body.String())
	}

	if waitForRemoval(filePath, noRemovalTimeout) {
		t.Fatal("Arquivo de outro usuário NÃO deveria ter sido removido")
	}
	if _, err := repo.GetMediaUploadByURL(victimURL); err != nil {
		t.Errorf("Registro de upload da vítima deveria continuar existindo: %v", err)
	}
}

func TestDeleteMessage_KeepsUnregisteredMedia(t *testing.T) {
	handler, repo, dir := setupMediaDeleteTest(t)
	filePath := writeUploadFile(t, dir, "img_legacy.png")

	_ = repo.CreateMessage(&models.Message{ID: "msg_legacy", ChannelID: "t1", ServerID: "1", AuthorID: "usr_dev_1", MediaURL: "http://localhost:8080/uploads/img_legacy.png"})

	if rr := deleteMessageAs(handler, "usr_dev_1", "msg_legacy"); rr.Code != http.StatusNoContent {
		t.Fatalf("Esperava 204, obteve %d: %s", rr.Code, rr.Body.String())
	}

	if waitForRemoval(filePath, noRemovalTimeout) {
		t.Error("Arquivo sem registro de upload não deveria ser removido")
	}
}

func TestDeleteMessage_KeepsMediaWhenMessageDeletionFails(t *testing.T) {
	handler, repo, dir := setupMediaDeleteTest(t)
	filePath := writeUploadFile(t, dir, "img_orphan.png")
	mediaURL := "http://localhost:8080/uploads/img_orphan.png"
	_ = repo.CreateMediaUpload(&models.MediaUpload{URL: mediaURL, OwnerID: "usr_dev_1", MediaType: "image/png"})

	// Mensagem inexistente: DeleteMessage falha (404) e nenhum arquivo deve ser tocado
	if rr := deleteMessageAs(handler, "usr_dev_1", "msg_missing"); rr.Code != http.StatusNotFound && rr.Code != http.StatusInternalServerError {
		t.Fatalf("Esperava 404 ou 500 para mensagem inexistente, obteve %d", rr.Code)
	}

	if waitForRemoval(filePath, noRemovalTimeout) {
		t.Error("Arquivo não deveria ser removido quando a exclusão da mensagem falha")
	}
}
