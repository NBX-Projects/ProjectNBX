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
		Broadcast:   make(chan *models.WSEvent, 256),
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
			totalClients := len(h.clients)
			h.mu.Unlock()

			log.Printf("[Hub] Usuário conectado: %s (%s). Total de conexões: %d", client.Username, client.UserID, totalClients)
			h.broadcastPresence(client.UserID, "online")

			// Envia sincronização de voz imediata para o cliente recém-conectado
			if len(currentVoiceStates) > 0 {
				payloadBytes, err := json.Marshal(currentVoiceStates)
				if err == nil {
					syncMsg, _ := json.Marshal(&models.WSEvent{
						Type:     models.EventVoiceSync,
						Payload:  payloadBytes,
						ServerID: client.ServerID,
					})
					client.SendEvent(syncMsg)
				}
			}

		case client := <-h.Unregister:
			var userWentOffline bool
			var leftVoiceEvents []*models.WSEvent

			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				client.Close()

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
					userWentOffline = true

					// Remove o usuário de canais de voz em todos os servidores caso tenha desconectado
					for sID, sMap := range h.voiceStates {
						for sid, st := range sMap {
							if st.UserID == client.UserID {
								leaveState := *st
								leaveState.IsInVoice = false
								leaveState.IsTransmitting = false
								payloadBytes, _ := json.Marshal(leaveState)
								leftVoiceEvents = append(leftVoiceEvents, &models.WSEvent{
									Type:      models.EventVoiceState,
									Payload:   payloadBytes,
									ChannelID: leaveState.ChannelID,
									ServerID:  sID,
								})
								delete(sMap, sid)
							}
						}
					}
				}
			}
			remainingClients := len(h.clients)
			h.mu.Unlock()

			log.Printf("[Hub] Usuário desconectado: %s. Conexões restantes: %d", client.UserID, remainingClients)

			// Notificações emitidas FORA do Lock para evitar qualquer deadlock com BroadcastEvent
			if userWentOffline {
				h.broadcastPresence(client.UserID, "offline")
				for _, ev := range leftVoiceEvents {
					h.BroadcastEvent(ev)
				}
			}

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
	clientsToBroadcast := make([]*Client, 0, len(h.clients))
	for client := range h.clients {
		if event.ServerID != "" && client.ServerID != "" && client.ServerID != event.ServerID {
			continue
		}
		clientsToBroadcast = append(clientsToBroadcast, client)
	}
	h.mu.RUnlock()

	for _, client := range clientsToBroadcast {
		if !client.SendEvent(data) {
			log.Printf("[Hub] Buffer cheio ou cliente desconectado %s, frame ignorado", client.UserID)
		}
	}
}

// HandleClientEvent processa mensagens enviadas pelo cliente Flutter via WebSocket
func (h *Hub) HandleClientEvent(client *Client, event *models.WSEvent) {
	if event.ServerID != "" {
		client.ServerID = event.ServerID
	}

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
		h.BroadcastEvent(outEvent)

	case models.EventVoiceState:
		var clientState models.VoiceParticipantState
		if err := json.Unmarshal(event.Payload, &clientState); err == nil {
			targetServerID := clientState.ServerID
			if targetServerID == "" {
				targetServerID = client.ServerID
			}
			sessionID := clientState.SessionID
			if sessionID == "" {
				sessionID = client.UserID
			}

			h.mu.Lock()
			sMap, serverExists := h.voiceStates[targetServerID]
			if !serverExists {
				sMap = make(map[string]*models.VoiceParticipantState)
				h.voiceStates[targetServerID] = sMap
			}
			st, userExists := sMap[sessionID]
			if !userExists && sessionID != client.UserID {
				st, userExists = sMap[client.UserID]
			}

			if !userExists {
				if clientState.IsInVoice {
					clientState.UserID = client.UserID
					clientState.ServerID = targetServerID
					sMap[sessionID] = &clientState
					st = &clientState
				} else {
					h.mu.Unlock()
					return
				}
			} else {
				if !clientState.IsInVoice {
					delete(sMap, sessionID)
					delete(sMap, client.UserID)
				}
			}

			st.IsInVoice = clientState.IsInVoice
			st.IsConnecting = clientState.IsConnecting
			st.IsMuted = clientState.IsMuted
			st.IsDeafened = clientState.IsDeafened
			st.IsSpeaking = clientState.IsSpeaking
			if clientState.StreamTitle != "" {
				st.StreamTitle = clientState.StreamTitle
			}
			if clientState.PreviewType != "" {
				st.PreviewType = clientState.PreviewType
			}
			if clientState.Thumbnail != "" {
				st.Thumbnail = clientState.Thumbnail
			}
			if clientState.Device != "" {
				st.Device = clientState.Device
			}
			copyState := *st
			h.mu.Unlock()

			updatedBytes, _ := json.Marshal(copyState)
			event.Payload = updatedBytes
			event.ServerID = copyState.ServerID
			event.ChannelID = copyState.ChannelID
			h.BroadcastEvent(event)
		}

	case models.EventVoiceSync:
		h.mu.RLock()
		var statesList []*models.VoiceParticipantState
		targetServerID := event.ServerID
		if targetServerID == "" {
			targetServerID = client.ServerID
		}
		if targetServerID != "" {
			if sMap, ok := h.voiceStates[targetServerID]; ok {
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
			ServerID: targetServerID,
		})
		client.SendEvent(replyMsg)

	case models.EventPing:
		pongPayload, _ := json.Marshal(map[string]string{"reply": "pong"})
		data, _ := json.Marshal(&models.WSEvent{
			Type:    models.EventPong,
			Payload: pongPayload,
		})
		client.SendEvent(data)
	}
}

func (h *Hub) broadcastPresence(userID, status string) {
	_ = h.Repo.UpdateUserStatus(userID, status)
	payload, _ := json.Marshal(&models.PresencePayload{
		UserID: userID,
		Status: status,
	})

	h.BroadcastEvent(&models.WSEvent{
		Type:    models.EventUserPresence,
		Payload: payload,
	})
}

// SetLiveKitParticipantState atualiza a presença do participante com base nos webhooks autoritativos do LiveKit SFU
func (h *Hub) SetLiveKitParticipantState(serverID, channelID, userID, username string, isInVoice bool, isTransmitting bool) {
	h.mu.Lock()
	if _, ok := h.voiceStates[serverID]; !ok {
		h.voiceStates[serverID] = make(map[string]*models.VoiceParticipantState)
	}

	sessionID := userID
	var outState models.VoiceParticipantState

	if isInVoice {
		existing, ok := h.voiceStates[serverID][sessionID]
		if ok {
			existing.IsInVoice = true
			existing.IsConnecting = false
			existing.ChannelID = channelID
			if username != "" {
				existing.Username = username
			}
			outState = *existing
		} else {
			outState = models.VoiceParticipantState{
				SessionID:      sessionID,
				UserID:         userID,
				Username:       username,
				ServerID:       serverID,
				ChannelID:      channelID,
				IsInVoice:      true,
				IsConnecting:   false,
				IsTransmitting: isTransmitting,
			}
			h.voiceStates[serverID][sessionID] = &outState
		}
	} else {
		if existing, ok := h.voiceStates[serverID][sessionID]; ok {
			outState = *existing
			outState.IsInVoice = false
			outState.IsTransmitting = false
			delete(h.voiceStates[serverID], sessionID)
		} else {
			outState = models.VoiceParticipantState{
				SessionID: sessionID,
				UserID:    userID,
				Username:  username,
				ServerID:  serverID,
				ChannelID: channelID,
				IsInVoice: false,
			}
		}
	}
	h.mu.Unlock()

	payloadBytes, err := json.Marshal(outState)
	if err == nil {
		h.BroadcastEvent(&models.WSEvent{
			Type:      models.EventVoiceState,
			Payload:   payloadBytes,
			ChannelID: channelID,
			ServerID:  serverID,
		})
	}
}

// ClearRoomVoiceStates limpa todos os participantes de uma sala encerrada no LiveKit
func (h *Hub) ClearRoomVoiceStates(serverID, channelID string) {
	h.mu.Lock()
	var leftStates []models.VoiceParticipantState
	if sMap, ok := h.voiceStates[serverID]; ok {
		for sid, st := range sMap {
			if st.ChannelID == channelID {
				leave := *st
				leave.IsInVoice = false
				leave.IsTransmitting = false
				leftStates = append(leftStates, leave)
				delete(sMap, sid)
			}
		}
	}
	h.mu.Unlock()

	for _, st := range leftStates {
		payloadBytes, _ := json.Marshal(st)
		h.BroadcastEvent(&models.WSEvent{
			Type:      models.EventVoiceState,
			Payload:   payloadBytes,
			ChannelID: channelID,
			ServerID:  serverID,
		})
	}
}

// UpdateParticipantTransmitting atualiza se o usuário está transmitindo tela (capturado via track LiveKit)
func (h *Hub) UpdateParticipantTransmitting(serverID, channelID, userID string, isTransmitting bool) {
	h.mu.Lock()
	sessionID := userID
	var updated *models.VoiceParticipantState
	if sMap, ok := h.voiceStates[serverID]; ok {
		if st, exists := sMap[sessionID]; exists {
			st.IsTransmitting = isTransmitting
			copyState := *st
			updated = &copyState
		}
	}
	h.mu.Unlock()

	if updated != nil {
		payloadBytes, _ := json.Marshal(updated)
		h.BroadcastEvent(&models.WSEvent{
			Type:      models.EventVoiceState,
			Payload:   payloadBytes,
			ChannelID: channelID,
			ServerID:  serverID,
		})
	}
}
