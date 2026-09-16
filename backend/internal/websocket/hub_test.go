package websocket

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
)

func TestHub_LifecycleAndBroadcast(t *testing.T) {
	repo := repository.NewMemoryRepository()
	hub := NewHub(repo)
	go hub.Run()

	client1 := &Client{
		Hub:      hub,
		Conn:     nil, // Not calling Read/Write pump
		Send:     make(chan []byte, 16),
		UserID:   "usr_1",
		Username: "User1",
		ServerID: "srv_1",
	}

	client2 := &Client{
		Hub:      hub,
		Conn:     nil,
		Send:     make(chan []byte, 16),
		UserID:   "usr_2",
		Username: "User2",
		ServerID: "srv_1",
	}

	// Register client 1
	hub.Register <- client1
	time.Sleep(20 * time.Millisecond)

	hub.mu.RLock()
	if len(hub.clients) != 1 {
		t.Errorf("Expected 1 client, got %d", len(hub.clients))
	}
	hub.mu.RUnlock()

	// Register client 2
	hub.Register <- client2
	time.Sleep(20 * time.Millisecond)

	hub.mu.RLock()
	if len(hub.clients) != 2 {
		t.Errorf("Expected 2 clients, got %d", len(hub.clients))
	}
	hub.mu.RUnlock()

	// Broadcast an event
	event := &models.WSEvent{
		Type:     "CHAT_MESSAGE",
		ServerID: "srv_1",
		Payload:  []byte(`{"message":"hello"}`),
	}
	hub.Broadcast <- event

	select {
	case msg := <-client1.Send:
		if len(msg) == 0 {
			t.Error("Expected non-empty message on client1.Send")
		}
	case <-time.After(100 * time.Millisecond):
		t.Error("Timeout waiting for message on client1")
	}

	select {
	case msg := <-client2.Send:
		if len(msg) == 0 {
			t.Error("Expected non-empty message on client2.Send")
		}
	case <-time.After(100 * time.Millisecond):
		t.Error("Timeout waiting for message on client2")
	}

	// Unregister client 1
	hub.Unregister <- client1
	time.Sleep(20 * time.Millisecond)

	hub.mu.RLock()
	if len(hub.clients) != 1 {
		t.Errorf("Expected 1 client after unregister, got %d", len(hub.clients))
	}
	hub.mu.RUnlock()
}

func TestHub_HandleClientEvents(t *testing.T) {
	repo := repository.NewMemoryRepository()
	hub := NewHub(repo)
	go hub.Run()

	client := &Client{
		Hub:      hub,
		Send:     make(chan []byte, 16),
		UserID:   "usr_1",
		Username: "User1",
		ServerID: "srv_1",
	}

	hub.Register <- client
	time.Sleep(20 * time.Millisecond)

	// Drain initial presence/sync events from registration
	time.Sleep(30 * time.Millisecond)
	for len(client.Send) > 0 {
		<-client.Send
	}

	// 1. CHAT_MESSAGE
	chatPayload := []byte(`{"content":"Hello from client"}`)
	hub.HandleClientEvent(client, &models.WSEvent{
		Type:      models.EventChatMessage,
		ServerID:  "srv_1",
		ChannelID: "chn_1",
		Payload:   chatPayload,
	})
	expectEvent(t, client.Send, models.EventChatMessage, 200*time.Millisecond)

	// 2. VOICE_STATE: Join voice
	voiceJoinPayload, _ := json.Marshal(models.VoiceParticipantState{
		SessionID:   "sess_1",
		UserID:      "usr_1",
		Username:    "User1",
		ServerID:    "srv_1",
		ChannelID:   "chn_voice",
		IsInVoice:   true,
		StreamTitle: "Live Code",
		PreviewType: "window",
		Thumbnail:   "thumb_base64",
		Device:      "desktop",
	})
	hub.HandleClientEvent(client, &models.WSEvent{
		Type:     models.EventVoiceState,
		ServerID: "srv_1",
		Payload:  voiceJoinPayload,
	})
	expectEvent(t, client.Send, models.EventVoiceState, 200*time.Millisecond)

	// 3. VOICE_SYNC
	hub.HandleClientEvent(client, &models.WSEvent{
		Type:     models.EventVoiceSync,
		ServerID: "srv_1",
	})
	expectEvent(t, client.Send, models.EventVoiceSync, 200*time.Millisecond)

	// 4. VOICE_STATE: Leave voice
	voiceLeavePayload, _ := json.Marshal(models.VoiceParticipantState{
		SessionID: "sess_1",
		UserID:    "usr_1",
		ServerID:  "srv_1",
		IsInVoice: false,
	})
	hub.HandleClientEvent(client, &models.WSEvent{
		Type:     models.EventVoiceState,
		ServerID: "srv_1",
		Payload:  voiceLeavePayload,
	})
	expectEvent(t, client.Send, models.EventVoiceState, 200*time.Millisecond)

	// 5. PING
	hub.HandleClientEvent(client, &models.WSEvent{
		Type: models.EventPing,
	})
	expectEvent(t, client.Send, models.EventPong, 200*time.Millisecond)
}

func expectEvent(t *testing.T, ch <-chan []byte, expectedType models.EventType, timeout time.Duration) *models.WSEvent {
	t.Helper()
	deadline := time.After(timeout)
	for {
		select {
		case msg := <-ch:
			var ev models.WSEvent
			if err := json.Unmarshal(msg, &ev); err == nil && ev.Type == expectedType {
				return &ev
			}
		case <-deadline:
			t.Fatalf("Timeout waiting for event type: %s", expectedType)
			return nil
		}
	}
}

func TestHub_LiveKitStateAndClear(t *testing.T) {
	repo := repository.NewMemoryRepository()
	hub := NewHub(repo)
	go hub.Run()

	client := &Client{
		Hub:      hub,
		Send:     make(chan []byte, 16),
		UserID:   "usr_test",
		Username: "TestUser",
		ServerID: "srv_1",
	}
	hub.Register <- client
	time.Sleep(20 * time.Millisecond)

	// 1. SetLiveKitParticipantState - Join
	hub.SetLiveKitParticipantState("srv_1", "chn_voice", "usr_test", "TestUser", true, false)
	time.Sleep(20 * time.Millisecond)

	// 2. UpdateParticipantTransmitting - Toggle true
	hub.UpdateParticipantTransmitting("srv_1", "chn_voice", "usr_test", true)
	time.Sleep(20 * time.Millisecond)

	// 3. ClearRoomVoiceStates
	hub.ClearRoomVoiceStates("srv_1", "chn_voice")
	time.Sleep(20 * time.Millisecond)

	// 4. SetLiveKitParticipantState - Leave
	hub.SetLiveKitParticipantState("srv_1", "chn_voice", "usr_test", "TestUser", false, false)
	time.Sleep(20 * time.Millisecond)

	// 5. broadcastPresence
	hub.broadcastPresence("usr_test", "idle")
	time.Sleep(20 * time.Millisecond)
}

func TestClient_SafeSendAndCloseConcurrently(t *testing.T) {
	client := &Client{
		Send:   make(chan []byte, 10),
		UserID: "usr_concurrent",
	}

	done := make(chan bool)

	// Goroutine 1: envia repetidamente
	go func() {
		for i := 0; i < 500; i++ {
			_ = client.SendEvent([]byte("test"))
		}
		done <- true
	}()

	// Goroutine 2: fecha de forma concorrente
	go func() {
		time.Sleep(1 * time.Millisecond)
		client.Close()
		client.Close() // Chamada dupla deve ser no-op seguro
		done <- true
	}()

	<-done
	<-done

	// Envio após fechamento deve retornar false e não causar panic
	if client.SendEvent([]byte("after close")) {
		t.Error("Expected SendEvent to return false after close")
	}
}

func TestHub_ServerIDFiltering(t *testing.T) {
	repo := repository.NewMemoryRepository()
	hub := NewHub(repo)
	go hub.Run()

	clientA := &Client{
		Hub:      hub,
		Send:     make(chan []byte, 16),
		UserID:   "usr_a",
		ServerID: "srv_a",
	}
	clientB := &Client{
		Hub:      hub,
		Send:     make(chan []byte, 16),
		UserID:   "usr_b",
		ServerID: "srv_b",
	}

	hub.Register <- clientA
	hub.Register <- clientB
	time.Sleep(30 * time.Millisecond)

	// Drena eventos iniciais de registro
	for len(clientA.Send) > 0 {
		<-clientA.Send
	}
	for len(clientB.Send) > 0 {
		<-clientB.Send
	}

	// Broadcast para srv_a
	hub.BroadcastEvent(&models.WSEvent{
		Type:     models.EventChatMessage,
		ServerID: "srv_a",
		Payload:  []byte(`{"msg":"for server A only"}`),
	})

	time.Sleep(30 * time.Millisecond)

	// clientA deve receber
	if len(clientA.Send) != 1 {
		t.Errorf("Expected clientA to receive 1 event, got %d", len(clientA.Send))
	}

	// clientB NÃO deve receber
	if len(clientB.Send) != 0 {
		t.Errorf("Expected clientB to receive 0 events, got %d", len(clientB.Send))
	}
}

