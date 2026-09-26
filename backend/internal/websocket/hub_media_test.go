package websocket

import (
	"encoding/json"
	"testing"

	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
)

const testMediaChannel = "chan_media_test"

func sendChatEvent(t *testing.T, hub *Hub, client *Client, payload map[string]string) {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("Falha ao serializar payload: %v", err)
	}
	hub.HandleClientEvent(client, &models.WSEvent{
		Type:      models.EventChatMessage,
		ChannelID: testMediaChannel,
		ServerID:  "srv_1",
		Payload:   raw,
	})
}

func channelMessages(t *testing.T, repo repository.Repository) []*models.Message {
	t.Helper()
	msgs, err := repo.ListMessagesByChannel(testMediaChannel, 0)
	if err != nil {
		t.Fatalf("Falha ao listar mensagens: %v", err)
	}
	return msgs
}

func newMediaTestHub(t *testing.T) (*Hub, *repository.MemoryRepository, *Client) {
	t.Helper()
	repo := repository.NewMemoryRepository()
	hub := NewHub(repo)
	client := &Client{Hub: hub, Send: make(chan []byte, 16), UserID: "usr_owner", ServerID: "srv_1"}
	return hub, repo, client
}

func TestHub_ChatMessage_AcceptsOwnMediaWithServerSideType(t *testing.T) {
	hub, repo, client := newMediaTestHub(t)
	mediaURL := "http://localhost:8080/uploads/img_own.gif"
	_ = repo.CreateMediaUpload(&models.MediaUpload{URL: mediaURL, OwnerID: "usr_owner", MediaType: "image/gif"})

	// O media_type do cliente deve ser ignorado em favor do registro do servidor
	sendChatEvent(t, hub, client, map[string]string{"media_url": mediaURL, "media_type": "text/html"})

	msgs := channelMessages(t, repo)
	if len(msgs) != 1 {
		t.Fatalf("Esperava 1 mensagem persistida, obteve %d", len(msgs))
	}
	if msgs[0].MediaURL != mediaURL {
		t.Errorf("MediaURL esperada %s, obteve %s", mediaURL, msgs[0].MediaURL)
	}
	if msgs[0].MediaType != "image/gif" {
		t.Errorf("MediaType deveria vir do registro (image/gif), obteve %s", msgs[0].MediaType)
	}
}

func TestHub_ChatMessage_RejectsMediaFromAnotherUser(t *testing.T) {
	hub, repo, client := newMediaTestHub(t)
	victimURL := "http://localhost:8080/uploads/img_victim.png"
	_ = repo.CreateMediaUpload(&models.MediaUpload{URL: victimURL, OwnerID: "usr_victim", MediaType: "image/png"})

	sendChatEvent(t, hub, client, map[string]string{"content": "olha", "media_url": victimURL})

	if msgs := channelMessages(t, repo); len(msgs) != 0 {
		t.Errorf("Mensagem com mídia de outro usuário não deveria ser persistida, obteve %d", len(msgs))
	}
}

func TestHub_ChatMessage_RejectsUnregisteredMediaURL(t *testing.T) {
	hub, repo, client := newMediaTestHub(t)

	sendChatEvent(t, hub, client, map[string]string{"media_url": "https://tracker.example.com/pixel.png"})

	if msgs := channelMessages(t, repo); len(msgs) != 0 {
		t.Errorf("Mensagem com URL externa não deveria ser persistida, obteve %d", len(msgs))
	}
}

func TestHub_ChatMessage_TextOnlyIgnoresClientMediaType(t *testing.T) {
	hub, repo, client := newMediaTestHub(t)

	sendChatEvent(t, hub, client, map[string]string{"content": "oi", "media_type": "image/png"})

	msgs := channelMessages(t, repo)
	if len(msgs) != 1 {
		t.Fatalf("Esperava 1 mensagem de texto, obteve %d", len(msgs))
	}
	if msgs[0].MediaType != "" || msgs[0].MediaURL != "" {
		t.Errorf("Mensagem de texto não deveria ter mídia, obteve url=%q type=%q", msgs[0].MediaURL, msgs[0].MediaType)
	}
}
