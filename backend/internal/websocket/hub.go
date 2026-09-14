package websocket

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
)

// Hub mantém o conjunto de clientes ativos e faz o roteamento das mensagens
type Hub struct {
	mu          sync.RWMutex
	clients     map[*Client]bool
	userConns   map[string][]*Client                               // userID -> lista de conexões ativas
	voiceStates map[string]map[string]*models.VoiceParticipantState // serverID -> (sessionID -> state)
	Register    chan *Client
	Unregister  chan *Client
	Broadcast   chan *models.WSEvent
	Repo        repository.Repository
}

func NewHub(repo repository.Repository) *Hub {
	return &Hub{
		clients:     make(map[*Client]bool),
		userConns:   make(map[string][]*Client),
		voiceStates: make(map[string]map[string]*models.VoiceParticipantState),
		Register:    make(chan *Client),
		Unregister:  make(chan *Client),
		Broadcast:   make(chan *models.WSEvent),
		Repo:        repo,
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.clients[client] = true
			h.userConns[client.UserID] = append(h.userConns[client.UserID], client)

			// Coleta estados de voz atuais deste servidor para sincronizar com o novo cliente
			var currentVoiceStates []*models.VoiceParticipantState
			if client.ServerID != "" {
				if sMap, ok := h.voiceStates[client.ServerID]; ok {
					for _, st := range sMap {
						currentVoiceStates = append(currentVoiceStates, st)
					}
				}
			}
			h.mu.Unlock()

			log.Printf("[Hub] Usuário conectado: %s (%s). Total de conexões: %d", client.Username, client.UserID, len(h.clients))
			h.broadcastPresence(client.UserID, "online")

			// Envia sincronização de voz imediata para o cliente recém-conectado
			if len(currentVoiceStates) > 0 {
				payloadBytes, err := json.Marshal(currentVoiceStates)
				if err == nil {
					syncMsg, _ := json.Marshal(&models.WSEvent{
						Type:      models.EventVoiceSync,
						Payload:   payloadBytes,
						ServerID:  client.ServerID,
					})
					select {
					case client.Send <- syncMsg:
					default:
					}
				}
			}

		case client := <-h.Unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.Send)

				// Remove das conexões do usuário
				conns := h.userConns[client.UserID]
				for i, c := range conns {
					if c == client {
						h.userConns[client.UserID] = append(conns[:i], conns[i+1:]...)
						break
					}
				}

				if len(h.userConns[client.UserID]) == 0 {
					delete(h.userConns, client.UserID)
					h.broadcastPresence(client.UserID, "offline")

					// Remove o usuário de canais de voz deste servidor se desconectou
					if client.ServerID != "" {
						if sMap, ok := h.voiceStates[client.ServerID]; ok {
							var removedStates []*models.VoiceParticipantState
							for sid, st := range sMap {
								if st.UserID == client.UserID {
									removedStates = append(removedStates, st)
									delete(sMap, sid)
								}
							}
							for _, r := range removedStates {
								leaveState := *r
								leaveState.IsInVoice = false
								leaveState.IsTransmitting = false
								payloadBytes, _ := json.Marshal(leaveState)
								leaveEvent := &models.WSEvent{
									Type:      models.EventVoiceState,
									Payload:   payloadBytes,
									ChannelID: leaveState.ChannelID,
									ServerID:  client.ServerID,
								}
								go func(ev *models.WSEvent) {
									h.Broadcast <- ev
								}(leaveEvent)
							}
						}
					}
				}
			}
			h.mu.Unlock()
			log.Printf("[Hub] Usuário desconectado: %s. Conexões restantes: %d", client.UserID, len(h.clients))

		case event := <-h.Broadcast:
			h.BroadcastEvent(event)
		}
	}
}

// BroadcastEvent envia um evento para todos os clientes relevantes
func (h *Hub) BroadcastEvent(event *models.WSEvent) {
	data, err := json.Marshal(event)
	if err != nil {
		log.Printf("[Hub] Erro ao serializar evento para broadcast: %v", err)
		return
	}

	h.mu.RLock()
	defer h.mu.RUnlock()

	for client := range h.clients {
		// Se o evento for restrito a um servidor específico, filtra conexões
		if event.ServerID != "" && client.ServerID != "" && client.ServerID != event.ServerID {
			continue
		}

		select {
		case client.Send <- data:
		default:
			close(client.Send)
			delete(h.clients, client)
		}
	}
}

// HandleClientEvent processa mensagens enviadas pelo cliente Flutter via WebSocket
func (h *Hub) HandleClientEvent(client *Client, event *models.WSEvent) {
	switch event.Type {
	case models.EventChatMessage:
		var req struct {
			Content string `json:"content"`
		}
		if err := json.Unmarshal(event.Payload, &req); err != nil || req.Content == "" {
			return
		}

		author, _ := h.Repo.GetUserByID(client.UserID)
		msg := &models.Message{
			ID:        uuid.New().String(),
			ChannelID: event.ChannelID,
			ServerID:  event.ServerID,
			AuthorID:  client.UserID,
			Author:    author,
			Content:   req.Content,
			CreatedAt: time.Now(),
		}

		// Persiste a mensagem no repositório
		_ = h.Repo.CreateMessage(msg)

		payloadBytes, _ := json.Marshal(msg)
		outEvent := &models.WSEvent{
			Type:      models.EventChatMessage,
			Payload:   payloadBytes,
			ChannelID: event.ChannelID,
			ServerID:  event.ServerID,
		}
		h.Broadcast <- outEvent

	case models.EventVoiceState:
		var state models.VoiceParticipantState
		if err := json.Unmarshal(event.Payload, &state); err == nil {
			if state.SessionID == "" {
				state.SessionID = client.UserID
			}
			if state.UserID == "" {
				state.UserID = client.UserID
			}
			if state.Username == "" {
				state.Username = client.Username
			}
			if state.ServerID == "" {
				state.ServerID = client.ServerID
			}
			if state.ChannelID == "" {
				state.ChannelID = event.ChannelID
			}

			h.mu.Lock()
			if state.IsInVoice {
				if _, ok := h.voiceStates[state.ServerID]; !ok {
					h.voiceStates[state.ServerID] = make(map[string]*models.VoiceParticipantState)
				}
				h.voiceStates[state.ServerID][state.SessionID] = &state
			} else {
				if sMap, ok := h.voiceStates[state.ServerID]; ok {
					delete(sMap, state.SessionID)
				}
			}
			h.mu.Unlock()

			// Re-serializa para garantir que todos os campos estejam populados no broadcast
			updatedBytes, _ := json.Marshal(state)
			event.Payload = updatedBytes
			event.ServerID = state.ServerID
			event.ChannelID = state.ChannelID
		}
		h.Broadcast <- event

	case models.EventVoiceSync:
		h.mu.RLock()
		var statesList []*models.VoiceParticipantState
		if client.ServerID != "" {
			if sMap, ok := h.voiceStates[client.ServerID]; ok {
				for _, st := range sMap {
					statesList = append(statesList, st)
				}
			}
		}
		h.mu.RUnlock()

		syncBytes, _ := json.Marshal(statesList)
		replyMsg, _ := json.Marshal(&models.WSEvent{
			Type:     models.EventVoiceSync,
			Payload:  syncBytes,
			ServerID: client.ServerID,
		})
		select {
		case client.Send <- replyMsg:
		default:
		}

	case models.EventPing:
		pongPayload, _ := json.Marshal(map[string]string{"reply": "pong"})
		data, _ := json.Marshal(&models.WSEvent{
			Type:    models.EventPong,
			Payload: pongPayload,
		})
		client.Send <- data
	}
}

func (h *Hub) broadcastPresence(userID, status string) {
	_ = h.Repo.UpdateUserStatus(userID, status)
	payload, _ := json.Marshal(&models.PresencePayload{
		UserID: userID,
		Status: status,
	})

	h.Broadcast <- &models.WSEvent{
		Type:    models.EventUserPresence,
		Payload: payload,
	}
}
