package screenshare

import (
	"context"
	"errors"
	"sync"
	"time"
)

var (
	ErrSessionNotFound      = errors.New("screen share session not found")
	ErrSessionAlreadyExists = errors.New("active screen share session already exists for channel")
	ErrViewerLimitReached   = errors.New("viewer limit reached")
)

// ScreenShareRepository coordena o estado das sessões de screen share
type ScreenShareRepository interface {
	Create(ctx context.Context, session *ChannelScreenShareState) error
	GetByChannel(ctx context.Context, channelID string) (*ChannelScreenShareState, error)
	GetBySession(ctx context.Context, sessionID string) (*ChannelScreenShareState, error)
	AddViewerIfCapacity(ctx context.Context, sessionID, userID string, maxViewers int) (bool, error)
	RemoveViewer(ctx context.Context, sessionID, userID string) error
	SetGracePeriod(ctx context.Context, sessionID string, graceUntil *time.Time) error
	Delete(ctx context.Context, sessionID string) error
}

// InMemoryScreenShareRepository implementação thread-safe em memória
type InMemoryScreenShareRepository struct {
	mu           sync.RWMutex
	bySessionID  map[string]*ChannelScreenShareState
	byChannelID  map[string]string // channelID -> sessionID
}

func NewInMemoryScreenShareRepository() *InMemoryScreenShareRepository {
	return &InMemoryScreenShareRepository{
		bySessionID: make(map[string]*ChannelScreenShareState),
		byChannelID: make(map[string]string),
	}
}

// copyState cria uma cópia profunda para evitar data races em leituras externas
func (r *InMemoryScreenShareRepository) copyState(s *ChannelScreenShareState) *ChannelScreenShareState {
	if s == nil {
		return nil
	}
	viewers := make(map[string]struct{}, len(s.ViewerUserIDs))
	for k := range s.ViewerUserIDs {
		viewers[k] = struct{}{}
	}
	var grace *time.Time
	if s.GraceUntil != nil {
		g := *s.GraceUntil
		grace = &g
	}
	return &ChannelScreenShareState{
		SessionID:     s.SessionID,
		ChannelID:     s.ChannelID,
		BroadcasterID: s.BroadcasterID,
		State:         s.State,
		Quality:       s.Quality,
		StartedAt:     s.StartedAt,
		GraceUntil:    grace,
		ViewerUserIDs: viewers,
	}
}

func (r *InMemoryScreenShareRepository) Create(ctx context.Context, session *ChannelScreenShareState) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if existingSessionID, exists := r.byChannelID[session.ChannelID]; exists {
		if existing, ok := r.bySessionID[existingSessionID]; ok && existing.State == SessionStateActive {
			return ErrSessionAlreadyExists
		}
	}

	viewers := make(map[string]struct{})
	if session.ViewerUserIDs != nil {
		for k := range session.ViewerUserIDs {
			viewers[k] = struct{}{}
		}
	}

	state := &ChannelScreenShareState{
		SessionID:     session.SessionID,
		ChannelID:     session.ChannelID,
		BroadcasterID: session.BroadcasterID,
		State:         SessionStateActive,
		Quality:       session.Quality,
		StartedAt:     session.StartedAt,
		GraceUntil:    session.GraceUntil,
		ViewerUserIDs: viewers,
	}

	r.bySessionID[session.SessionID] = state
	r.byChannelID[session.ChannelID] = session.SessionID
	return nil
}

func (r *InMemoryScreenShareRepository) GetByChannel(ctx context.Context, channelID string) (*ChannelScreenShareState, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	sessionID, exists := r.byChannelID[channelID]
	if !exists {
		return nil, ErrSessionNotFound
	}
	session, exists := r.bySessionID[sessionID]
	if !exists || session.State != SessionStateActive {
		return nil, ErrSessionNotFound
	}
	return r.copyState(session), nil
}

func (r *InMemoryScreenShareRepository) GetBySession(ctx context.Context, sessionID string) (*ChannelScreenShareState, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	session, exists := r.bySessionID[sessionID]
	if !exists {
		return nil, ErrSessionNotFound
	}
	return r.copyState(session), nil
}

func (r *InMemoryScreenShareRepository) AddViewerIfCapacity(ctx context.Context, sessionID, userID string, maxViewers int) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	session, exists := r.bySessionID[sessionID]
	if !exists || session.State != SessionStateActive {
		return false, ErrSessionNotFound
	}

	// Idempotência: se já estiver na lista, retorna sucesso sem duplicar
	if _, alreadyViewer := session.ViewerUserIDs[userID]; alreadyViewer {
		return true, nil
	}

	if len(session.ViewerUserIDs) >= maxViewers {
		return false, ErrViewerLimitReached
	}

	session.ViewerUserIDs[userID] = struct{}{}
	return true, nil
}

func (r *InMemoryScreenShareRepository) RemoveViewer(ctx context.Context, sessionID, userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	session, exists := r.bySessionID[sessionID]
	if !exists {
		return ErrSessionNotFound
	}

	delete(session.ViewerUserIDs, userID)
	return nil
}

func (r *InMemoryScreenShareRepository) SetGracePeriod(ctx context.Context, sessionID string, graceUntil *time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	session, exists := r.bySessionID[sessionID]
	if !exists {
		return ErrSessionNotFound
	}

	session.GraceUntil = graceUntil
	return nil
}

func (r *InMemoryScreenShareRepository) Delete(ctx context.Context, sessionID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	session, exists := r.bySessionID[sessionID]
	if !exists {
		return nil
	}

	session.State = SessionStateStopped
	delete(r.byChannelID, session.ChannelID)
	delete(r.bySessionID, session.SessionID)
	return nil
}
