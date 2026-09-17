package screenshare

import (
	"context"
	"encoding/json"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/projectnbx/backend/internal/models"
)

type mockRouter struct {
	mu             sync.Mutex
	routedToUser   map[string][]*WebRTCSignalingEvent
	broadcastEvents []*models.WSEvent
}

func newMockRouter() *mockRouter {
	return &mockRouter{
		routedToUser:   make(map[string][]*WebRTCSignalingEvent),
		broadcastEvents: make([]*models.WSEvent, 0),
	}
}

func (m *mockRouter) RouteToUser(userID string, event *WebRTCSignalingEvent) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.routedToUser[userID] = append(m.routedToUser[userID], event)
	return nil
}

func (m *mockRouter) BroadcastToChannel(channelID, serverID string, event *models.WSEvent) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.broadcastEvents = append(m.broadcastEvents, event)
	return nil
}

func (m *mockRouter) getEventsForUser(userID string) []*WebRTCSignalingEvent {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]*WebRTCSignalingEvent(nil), m.routedToUser[userID]...)
}

func TestScreenShareRepository_AddViewerIfCapacity_Concurrent(t *testing.T) {
	repo := NewInMemoryScreenShareRepository()
	ctx := context.Background()
	sessionID := "test-session-1"
	channelID := "test-channel-1"
	broadcasterID := "user-host"

	state := &ChannelScreenShareState{
		SessionID:     sessionID,
		ChannelID:     channelID,
		BroadcasterID: broadcasterID,
		State:         SessionStateActive,
		Quality:       "high",
		StartedAt:     time.Now(),
		ViewerUserIDs: make(map[string]struct{}),
	}

	if err := repo.Create(ctx, state); err != nil {
		t.Fatalf("Erro ao criar sessão: %v", err)
	}

	maxViewers := 5
	totalAttempts := 10
	var acceptedCount int32
	var rejectedCount int32
	var wg sync.WaitGroup

	for i := 1; i <= totalAttempts; i++ {
		wg.Add(1)
		viewerID := string(rune('A' + i)) // "B", "C", "D"...
		go func(uid string) {
			defer wg.Done()
			ok, err := repo.AddViewerIfCapacity(ctx, sessionID, uid, maxViewers)
			if err == nil && ok {
				atomic.AddInt32(&acceptedCount, 1)
			} else {
				atomic.AddInt32(&rejectedCount, 1)
			}
		}(viewerID)
	}

	wg.Wait()

	if acceptedCount != int32(maxViewers) {
		t.Errorf("Esperado exatamente %d aceitos, obtido %d", maxViewers, acceptedCount)
	}
	if rejectedCount != int32(totalAttempts-maxViewers) {
		t.Errorf("Esperado exatamente %d rejeitados, obtido %d", totalAttempts-maxViewers, rejectedCount)
	}

	// Valida idempotência: o mesmo viewer entrando novamente deve retornar sucesso sem aumentar a contagem
	sess, err := repo.GetBySession(ctx, sessionID)
	if err != nil {
		t.Fatalf("Erro ao buscar sessão: %v", err)
	}
	if len(sess.ViewerUserIDs) != maxViewers {
		t.Errorf("Esperado exatamente %d viewers no estado, obtido %d", maxViewers, len(sess.ViewerUserIDs))
	}

	// Pega um dos viewers existentes e testa idempotência
	for existingViewer := range sess.ViewerUserIDs {
		ok, err := repo.AddViewerIfCapacity(ctx, sessionID, existingViewer, maxViewers)
		if err != nil || !ok {
			t.Errorf("Idempotência falhou para viewer já conectado: %v", err)
		}
		break
	}
}

func TestScreenShareService_Start_Join_Stop_Flow(t *testing.T) {
	repo := NewInMemoryScreenShareRepository()
	router := newMockRouter()
	config := DefaultScreenShareConfig()
	turnService := NewTURNService(DefaultTURNConfig())

	// Membership mock: todos estão no canal "chan-1"
	membership := func(serverID, channelID, userID string) bool {
		return channelID == "chan-1"
	}

	service := NewService(repo, turnService, config, router, membership)
	ctx := context.Background()

	hostID := "user-host-1"
	viewerID := "user-viewer-1"

	// 1. Host inicia transmissão
	service.HandleStart(ctx, hostID, "server-1", &WebRTCSignalingRequest{
		Type:      models.EventScreenShareStart,
		ChannelID: "chan-1",
		Quality:   "high",
	})

	hostEvents := router.getEventsForUser(hostID)
	if len(hostEvents) != 1 || hostEvents[0].Type != models.EventScreenShareStarted {
		t.Fatalf("Esperado SCREEN_SHARE_STARTED para o host, obtido %v", hostEvents)
	}

	var startedPayload ScreenShareStartedPayload
	if err := json.Unmarshal([]byte(hostEvents[0].SDP), &startedPayload); err != nil {
		t.Fatalf("Erro ao decodificar startedPayload: %v", err)
	}
	sessionID := startedPayload.SessionID
	if sessionID == "" {
		t.Fatal("session_id retornado está vazio")
	}

	// 2. Viewer faz JOIN
	service.HandleJoin(ctx, viewerID, "server-1", &WebRTCSignalingRequest{
		Type:      models.EventScreenShareJoin,
		ChannelID: "chan-1",
		SessionID: sessionID,
	})

	viewerEvents := router.getEventsForUser(viewerID)
	if len(viewerEvents) != 1 || viewerEvents[0].Type != models.EventScreenShareJoined {
		t.Fatalf("Esperado SCREEN_SHARE_JOINED para o viewer, obtido %v", viewerEvents)
	}

	// Host deve receber SCREEN_SHARE_VIEWER_JOINED
	hostEventsAfterJoin := router.getEventsForUser(hostID)
	if len(hostEventsAfterJoin) != 2 || hostEventsAfterJoin[1].Type != models.EventScreenShareViewerJoined {
		t.Fatalf("Esperado SCREEN_SHARE_VIEWER_JOINED para o host, obtido %v", hostEventsAfterJoin)
	}

	// 3. Troca de sinalização (Offer do Host para Viewer)
	service.HandleSignaling(ctx, hostID, "server-1", &WebRTCSignalingRequest{
		Type:          models.EventWebRTCOffer,
		ChannelID:     "chan-1",
		SessionID:     sessionID,
		NegotiationID: "neg-1",
		Sequence:      1,
		ToUserID:      viewerID,
		SDP:           "v=0\r\no=host...",
	})

	viewerSignalingEvents := router.getEventsForUser(viewerID)
	if len(viewerSignalingEvents) != 2 || viewerSignalingEvents[1].Type != models.EventWebRTCOffer {
		t.Fatalf("Esperado WEBRTC_OFFER repassado para o viewer, obtido %v", viewerSignalingEvents)
	}
	if viewerSignalingEvents[1].FromUserID != hostID {
		t.Errorf("FromUserID esperado %s, obtido %s", hostID, viewerSignalingEvents[1].FromUserID)
	}

	// 4. Viewer tenta parar (deve ser rejeitado - apenas host pode parar)
	service.HandleStop(ctx, viewerID, "server-1", &WebRTCSignalingRequest{
		Type:      models.EventScreenShareStop,
		ChannelID: "chan-1",
		SessionID: sessionID,
	})

	// Sessão ainda deve existir
	sess, err := repo.GetBySession(ctx, sessionID)
	if err != nil || sess == nil || sess.State != SessionStateActive {
		t.Fatal("Sessão não deveria ter sido encerrada por um viewer")
	}

	// 5. Host para a transmissão
	service.HandleStop(ctx, hostID, "server-1", &WebRTCSignalingRequest{
		Type:      models.EventScreenShareStop,
		ChannelID: "chan-1",
		SessionID: sessionID,
	})

	sessAfterStop, _ := repo.GetBySession(ctx, sessionID)
	if sessAfterStop != nil {
		t.Fatal("Sessão deveria ter sido removida do repositório")
	}
}

func TestScreenShareService_AntiBOLA_ChannelValidation(t *testing.T) {
	repo := NewInMemoryScreenShareRepository()
	router := newMockRouter()
	config := DefaultScreenShareConfig()
	turnService := NewTURNService(DefaultTURNConfig())

	// Apenas user-allowed está no canal chan-allowed
	membership := func(serverID, channelID, userID string) bool {
		return channelID == "chan-allowed" && userID == "user-allowed"
	}

	service := NewService(repo, turnService, config, router, membership)
	ctx := context.Background()

	// Tentativa de Start por usuário não matriculado
	service.HandleStart(ctx, "attacker-user", "server-1", &WebRTCSignalingRequest{
		Type:      models.EventScreenShareStart,
		ChannelID: "chan-allowed",
	})

	attackerEvents := router.getEventsForUser("attacker-user")
	if len(attackerEvents) != 1 || attackerEvents[0].Type != models.EventScreenShareError {
		t.Fatalf("Esperado SCREEN_SHARE_ERROR para usuário não autorizado, obtido %v", attackerEvents)
	}
}

func TestTURNService_GenerateCredentials_RFC5766(t *testing.T) {
	config := TURNConfig{
		Enabled:       true,
		URLs:          []string{"turn:turn.example.com:3478?transport=udp"},
		Secret:        "supersecret123",
		CredentialTTL: 1 * time.Hour,
	}
	service := NewTURNService(config)

	creds, err := service.GenerateCredentials("test-user-42")
	if err != nil {
		t.Fatalf("Erro ao gerar credenciais TURN: %v", err)
	}

	if len(creds.URLs) == 0 || creds.URLs[0] != "turn:turn.example.com:3478?transport=udp" {
		t.Errorf("URLs inválidas no response: %v", creds.URLs)
	}
	if creds.Username == "" || creds.Credential == "" {
		t.Errorf("Username ou Credential vazios no response: %v", creds)
	}
	if creds.ExpiresAt <= time.Now().Unix() {
		t.Errorf("ExpiresAt no passado: %d", creds.ExpiresAt)
	}
}

func TestRateLimiter_TokenBucket(t *testing.T) {
	rl := NewRateLimiter()
	userID := "spam-user"

	// START permite burst de 5
	for i := 0; i < 5; i++ {
		if !rl.Allow(userID, models.EventScreenShareStart) {
			t.Errorf("Tentativa %d de START deveria ter sido permitida", i+1)
		}
	}

	// 6ª tentativa imediata deve ser bloqueada
	if rl.Allow(userID, models.EventScreenShareStart) {
		t.Error("6ª tentativa imediata de START deveria ter sido bloqueada pelo rate limiter")
	}
}
