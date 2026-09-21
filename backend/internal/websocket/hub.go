package websocket

import (
	"context"
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/screenshare"
)

// Hub mantém o conjunto de clientes ativos e faz o roteamento das mensagens
type Hub struct {
	mu                 sync.RWMutex
	clients            map[*Client]bool
	userConns          map[string][]*Client                                // userID -> lista de conexões ativas
	voiceStates        map[string]map[string]*models.VoiceParticipantState // serverID -> (sessionID -> state)
	Register           chan *Client
	Unregister         chan *Client
	Broadcast          chan *models.WSEvent
	Repo               repository.Repository
	ScreenShareService *screenshare.Service
}

func NewHub(repo repository.Repository) *Hub {
	hub := &Hub{
		clients:     make(map[*Client]bool),
		userConns:   make(map[string][]*Client),
		voiceStates: make(map[string]map[string]*models.VoiceParticipantState),
		Register:    make(chan *Client),
		Unregister:  make(chan *Client),
		Broadcast:   make(chan *models.WSEvent, 256),
		Repo:        repo,
	}

	repoSS := screenshare.NewInMemoryScreenShareRepository()
	turnService := screenshare.NewTURNService(screenshare.DefaultTURNConfig())
	configSS := screenshare.DefaultScreenShareConfig()
	hub.ScreenShareService = screenshare.NewService(
		repoSS,
		turnService,
		configSS,
		hub,
		hub.isUserInChannel,
	)

	return hub
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

			// Notifica o serviço de screen share para tratar grace period do broadcaster ou saída de viewers
			h.ScreenShareService.OnUserDisconnected(context.Background(), client.UserID, client.ServerID, h.isUserOnline)

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
			userID := clientState.UserID
			if userID == "" {
				userID = client.UserID
			}
			sessionID := clientState.SessionID
			if sessionID == "" {
				sessionID = userID
			}

			var oldLeaveEvent *models.WSEvent
			var crossServerLeaveEvents []*models.WSEvent

			h.mu.Lock()
			sMap, serverExists := h.voiceStates[targetServerID]
			if !serverExists {
				sMap = make(map[string]*models.VoiceParticipantState)
				h.voiceStates[targetServerID] = sMap
			}

			// Localiza qualquer estado pré-existente deste usuário no servidor de destino
			var existingKey string
			var st *models.VoiceParticipantState
			for k, v := range sMap {
				if v.UserID == userID || k == userID || k == sessionID {
					existingKey = k
					st = v
					break
				}
			}

			var oldChannelID string
			if st != nil {
				oldChannelID = st.ChannelID
			}

			if !clientState.IsInVoice {
				// Usuário desconectou do canal de voz
				if existingKey != "" {
					delete(sMap, existingKey)
				}
				delete(sMap, userID)
				delete(sMap, sessionID)

				targetChannelID := clientState.ChannelID
				if targetChannelID == "" {
					targetChannelID = oldChannelID
				}
				h.mu.Unlock()

				clientState.UserID = userID
				clientState.ServerID = targetServerID
				clientState.ChannelID = targetChannelID
				clientState.IsInVoice = false
				clientState.IsTransmitting = false

				leaveBytes, _ := json.Marshal(clientState)
				event.Payload = leaveBytes
				event.ServerID = targetServerID
				event.ChannelID = targetChannelID
				h.BroadcastEvent(event)
				return
			}

			// Usuário está conectado/conectando na voz
			// Se o usuário está entrando em voz neste servidor, remove-o de QUALQUER outro servidor onde estivesse em chamada
			for sID, otherSMap := range h.voiceStates {
				if sID == targetServerID {
					continue
				}
				for k, existingSt := range otherSMap {
					if existingSt.UserID == userID || k == userID || k == sessionID {
						otherLeaveState := *existingSt
						otherLeaveState.IsInVoice = false
						otherLeaveState.IsTransmitting = false
						if otherLeaveBytes, err := json.Marshal(otherLeaveState); err == nil {
							crossServerLeaveEvents = append(crossServerLeaveEvents, &models.WSEvent{
								Type:      models.EventVoiceState,
								Payload:   otherLeaveBytes,
								ChannelID: otherLeaveState.ChannelID,
								ServerID:  sID,
							})
						}
						delete(otherSMap, k)
						delete(otherSMap, userID)
						delete(otherSMap, sessionID)
					}
				}
			}

			// Se estava em outro canal de voz no mesmo servidor, prepara saída do canal anterior
			if oldChannelID != "" && clientState.ChannelID != "" && oldChannelID != clientState.ChannelID {
				oldLeave := models.VoiceParticipantState{
					SessionID:      sessionID,
					UserID:         userID,
					Username:       clientState.Username,
					ServerID:       targetServerID,
					ChannelID:      oldChannelID,
					IsInVoice:      false,
					IsTransmitting: false,
				}
				if oldBytes, err := json.Marshal(oldLeave); err == nil {
					oldLeaveEvent = &models.WSEvent{
						Type:      models.EventVoiceState,
						Payload:   oldBytes,
						ChannelID: oldChannelID,
						ServerID:  targetServerID,
					}
				}
			}

			if st == nil {
				clientState.UserID = userID
				clientState.ServerID = targetServerID
				if clientState.SessionID == "" {
					clientState.SessionID = sessionID
				}
				st = &clientState
			} else {
				st.UserID = userID
				st.ServerID = targetServerID
				if clientState.ChannelID != "" {
					st.ChannelID = clientState.ChannelID
				}
				st.IsInVoice = true
				st.IsConnecting = clientState.IsConnecting
				st.IsTransmitting = clientState.IsTransmitting
				st.IsMuted = clientState.IsMuted
				st.IsDeafened = clientState.IsDeafened
				st.IsSpeaking = clientState.IsSpeaking
				if clientState.Username != "" {
					st.Username = clientState.Username
				}
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
				if clientState.SessionID != "" {
					st.SessionID = clientState.SessionID
				}
			}

			// Padroniza a chave sempre por userID para evitar duplicatas por sessionID
			if existingKey != "" && existingKey != userID {
				delete(sMap, existingKey)
			}
			delete(sMap, sessionID)
			sMap[userID] = st
			copyState := *st
			h.mu.Unlock()

			// Emite eventos FORA do lock para evitar qualquer deadlock
			if oldLeaveEvent != nil {
				h.BroadcastEvent(oldLeaveEvent)
			}
			for _, crossLeave := range crossServerLeaveEvents {
				h.BroadcastEvent(crossLeave)
			}

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

	// Eventos de Screen Sharing e WebRTC P2P
	case models.EventScreenShareStart:
		var req screenshare.WebRTCSignalingRequest
		if err := json.Unmarshal(event.Payload, &req); err == nil {
			req.Type = models.EventScreenShareStart
			if req.ChannelID == "" {
				req.ChannelID = event.ChannelID
			}
			h.ScreenShareService.HandleStart(context.Background(), client.UserID, client.ServerID, &req)
		}

	case models.EventScreenShareJoin:
		var req screenshare.WebRTCSignalingRequest
		if err := json.Unmarshal(event.Payload, &req); err == nil {
			req.Type = models.EventScreenShareJoin
			if req.ChannelID == "" {
				req.ChannelID = event.ChannelID
			}
			h.ScreenShareService.HandleJoin(context.Background(), client.UserID, client.ServerID, &req)
		}

	case models.EventScreenShareStop:
		var req screenshare.WebRTCSignalingRequest
		if err := json.Unmarshal(event.Payload, &req); err == nil {
			req.Type = models.EventScreenShareStop
			if req.ChannelID == "" {
				req.ChannelID = event.ChannelID
			}
			h.ScreenShareService.HandleStop(context.Background(), client.UserID, client.ServerID, &req)
		}

	case models.EventWebRTCOffer, models.EventWebRTCAnswer, models.EventWebRTCICECandidate:
		var req screenshare.WebRTCSignalingRequest
		if err := json.Unmarshal(event.Payload, &req); err == nil {
			req.Type = event.Type
			if req.ChannelID == "" {
				req.ChannelID = event.ChannelID
			}
			h.ScreenShareService.HandleSignaling(context.Background(), client.UserID, client.ServerID, &req)
		}
	}
}

// RouteToUser encaminha mensagens de sinalização diretamente para todas as conexões ativas de um usuário
func (h *Hub) RouteToUser(userID string, event *screenshare.WebRTCSignalingEvent) error {
	payloadBytes, err := json.Marshal(event)
	if err != nil {
		return err
	}
	wsEvent := &models.WSEvent{
		Type:      event.Type,
		Payload:   payloadBytes,
		ChannelID: event.ChannelID,
	}
	data, err := json.Marshal(wsEvent)
	if err != nil {
		return err
	}

	h.mu.RLock()
	conns, exists := h.userConns[userID]
	connsCopy := make([]*Client, len(conns))
	copy(connsCopy, conns)
	h.mu.RUnlock()

	if !exists || len(connsCopy) == 0 {
		return nil
	}

	for _, client := range connsCopy {
		client.SendEvent(data)
	}
	return nil
}

// BroadcastToChannel faz broadcast de um evento para o canal especificado
func (h *Hub) BroadcastToChannel(channelID, serverID string, event *models.WSEvent) error {
	event.ChannelID = channelID
	event.ServerID = serverID
	h.BroadcastEvent(event)
	return nil
}

func (h *Hub) isUserInChannel(serverID, channelID, userID string) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()

	// 1. Verifica nos estados de voz do servidor informado
	if sMap, ok := h.voiceStates[serverID]; ok {
		for _, st := range sMap {
			if st.UserID == userID && st.ChannelID == channelID && st.IsInVoice {
				return true
			}
		}
	}

	// 2. Busca em todos os servidores registrados no hub
	for _, sMap := range h.voiceStates {
		for _, st := range sMap {
			if st.UserID == userID && st.ChannelID == channelID && st.IsInVoice {
				return true
			}
		}
	}

	// 3. Fallback: se o usuário possui conexão ativa no WebSocket
	conns, exists := h.userConns[userID]
	return exists && len(conns) > 0
}

func (h *Hub) isUserOnline(userID string) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	conns, exists := h.userConns[userID]
	return exists && len(conns) > 0
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
	var crossServerLeaveEvents []*models.WSEvent

	h.mu.Lock()
	if _, ok := h.voiceStates[serverID]; !ok {
		h.voiceStates[serverID] = make(map[string]*models.VoiceParticipantState)
	}

	// Limpa qualquer chave residual/duplicada do mesmo usuário neste servidor
	for k, v := range h.voiceStates[serverID] {
		if v.UserID == userID && k != userID {
			delete(h.voiceStates[serverID], k)
		}
	}

	// Se o usuário está entrando em voz via LiveKit, remove-o de QUALQUER outro servidor onde estivesse em chamada
	if isInVoice {
		for sID, otherSMap := range h.voiceStates {
			if sID == serverID {
				continue
			}
			for k, existingSt := range otherSMap {
				if existingSt.UserID == userID || k == userID {
					otherLeaveState := *existingSt
					otherLeaveState.IsInVoice = false
					otherLeaveState.IsTransmitting = false
					if otherLeaveBytes, err := json.Marshal(otherLeaveState); err == nil {
						crossServerLeaveEvents = append(crossServerLeaveEvents, &models.WSEvent{
							Type:      models.EventVoiceState,
							Payload:   otherLeaveBytes,
							ChannelID: otherLeaveState.ChannelID,
							ServerID:  sID,
						})
					}
					delete(otherSMap, k)
					delete(otherSMap, userID)
				}
			}
		}
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

	for _, crossLeave := range crossServerLeaveEvents {
		h.BroadcastEvent(crossLeave)
	}

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
