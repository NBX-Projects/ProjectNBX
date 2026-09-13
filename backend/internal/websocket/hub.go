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
	mu         sync.RWMutex
	clients    map[*Client]bool
	userConns  map[string][]*Client // userID -> lista de conexões ativas
	Register   chan *Client
	Unregister chan *Client
	Broadcast  chan *models.WSEvent
	Repo       repository.Repository
}

func NewHub(repo repository.Repository) *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		userConns:  make(map[string][]*Client),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Broadcast:  make(chan *models.WSEvent),
		Repo:       repo,
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.clients[client] = true
			h.userConns[client.UserID] = append(h.userConns[client.UserID], client)
			h.mu.Unlock()

			log.Printf("[Hub] Usuário conectado: %s (%s). Total de conexões: %d", client.Username, client.UserID, len(h.clients))
			h.broadcastPresence(client.UserID, "online")

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
		// Reencaminha atualização de estado de voz (is_speaking, is_muted, is_deafened)
		h.Broadcast <- event

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
