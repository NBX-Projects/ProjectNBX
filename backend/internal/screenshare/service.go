package screenshare

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/projectnbx/backend/internal/models"
)

// ChannelMembershipChecker função para validar se um usuário está no canal especificado
type ChannelMembershipChecker func(serverID, channelID, userID string) bool

// Service coordena as regras de negócio de Screen Sharing P2P
type Service struct {
	repo        ScreenShareRepository
	rateLimiter *RateLimiter
	turnService *TURNService
	config      ScreenShareConfig
	router      SignalingRouter
	membership  ChannelMembershipChecker
}

func NewService(
	repo ScreenShareRepository,
	turnService *TURNService,
	config ScreenShareConfig,
	router SignalingRouter,
	membership ChannelMembershipChecker,
) *Service {
	return &Service{
		repo:        repo,
		rateLimiter: NewRateLimiter(),
		turnService: turnService,
		config:      config,
		router:      router,
		membership:  membership,
	}
}

func (s *Service) GetRepository() ScreenShareRepository {
	return s.repo
}

func (s *Service) GetTURNService() *TURNService {
	return s.turnService
}

func (s *Service) sendErrorToUser(userID, channelID, sessionID, code, message string) {
	payload, _ := json.Marshal(&ScreenShareErrorPayload{
		Code:      code,
		Message:   message,
		SessionID: sessionID,
		ChannelID: channelID,
	})
	outEv := &WebRTCSignalingEvent{
		WebRTCSignalingRequest: WebRTCSignalingRequest{
			Type:      models.EventScreenShareError,
			ChannelID: channelID,
			SessionID: sessionID,
		},
		FromUserID: "system",
	}
	outEv.SDP = string(payload)
	_ = s.router.RouteToUser(userID, outEv)
}

// HandleStart inicia uma nova sessão de transmissão
func (s *Service) HandleStart(ctx context.Context, userID, serverID string, req *WebRTCSignalingRequest) {
	if !s.rateLimiter.Allow(userID, models.EventScreenShareStart) {
		s.sendErrorToUser(userID, req.ChannelID, "", ErrWebRTCSignalingRateLimited, "Muitas tentativas de iniciar compartilhamento de tela")
		return
	}

	if req.ChannelID == "" {
		s.sendErrorToUser(userID, req.ChannelID, "", ErrWebRTCSignalingInvalidPayload, "channel_id é obrigatório")
		return
	}

	// Validação Anti-BOLA de canal
	if s.membership != nil && !s.membership(serverID, req.ChannelID, userID) {
		s.sendErrorToUser(userID, req.ChannelID, "", ErrWebRTCSignalingUnauthorized, "Usuário não está presente no canal informado")
		return
	}

	// Proíbe SDP e Candidate no START
	if req.SDP != "" || req.Candidate != nil {
		s.sendErrorToUser(userID, req.ChannelID, "", ErrWebRTCSignalingInvalidPayload, "SDP e Candidate são proibidos na mensagem SCREEN_SHARE_START")
		return
	}

	quality := req.Quality
	if quality == "" {
		quality = "medium"
	}

	sessionID := uuid.New().String()
	now := time.Now()

	state := &ChannelScreenShareState{
		SessionID:     sessionID,
		ChannelID:     req.ChannelID,
		BroadcasterID: userID,
		State:         SessionStateActive,
		Quality:       quality,
		StartedAt:     now,
		ViewerUserIDs: make(map[string]struct{}),
	}

	if err := s.repo.Create(ctx, state); err != nil {
		if errorsIs(err, ErrSessionAlreadyExists) {
			s.sendErrorToUser(userID, req.ChannelID, "", ErrScreenShareAlreadyActive, "Já existe uma transmissão ativa neste canal")
			return
		}
		s.sendErrorToUser(userID, req.ChannelID, "", ErrWebRTCSignalingInvalidState, "Erro ao criar sessão de compartilhamento de tela")
		return
	}

	// Envia confirmação SCREEN_SHARE_STARTED para o host
	startedPayload, _ := json.Marshal(&ScreenShareStartedPayload{
		SessionID:     sessionID,
		ChannelID:     req.ChannelID,
		BroadcasterID: userID,
		Quality:       quality,
		StartedAt:     now,
	})
	_ = s.router.RouteToUser(userID, &WebRTCSignalingEvent{
		WebRTCSignalingRequest: WebRTCSignalingRequest{
			Type:      models.EventScreenShareStarted,
			ChannelID: req.ChannelID,
			SessionID: sessionID,
			SDP:       string(startedPayload),
		},
		FromUserID: "system",
	})

	// Broadcast SCREEN_SHARE_AVAILABLE para o canal
	availPayload, _ := json.Marshal(&ScreenShareAvailablePayload{
		SessionID:     sessionID,
		ChannelID:     req.ChannelID,
		BroadcasterID: userID,
		Quality:       quality,
		StartedAt:     now,
	})
	_ = s.router.BroadcastToChannel(req.ChannelID, serverID, &models.WSEvent{
		Type:      models.EventScreenShareAvailable,
		Payload:   availPayload,
		ChannelID: req.ChannelID,
		ServerID:  serverID,
	})
}

// HandleJoin processa a entrada de um espectador na transmissão
func (s *Service) HandleJoin(ctx context.Context, userID, serverID string, req *WebRTCSignalingRequest) {
	if !s.rateLimiter.Allow(userID, models.EventScreenShareJoin) {
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingRateLimited, "Muitas tentativas de entrar na transmissão")
		return
	}

	if req.SessionID == "" {
		s.sendErrorToUser(userID, req.ChannelID, "", ErrScreenShareInvalidSession, "session_id é obrigatório")
		return
	}

	session, err := s.repo.GetBySession(ctx, req.SessionID)
	if err != nil || session == nil || session.State != SessionStateActive {
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrScreenShareSessionNotFound, "Sessão de transmissão não encontrada ou inativa")
		return
	}

	// Validação Anti-BOLA de canal
	if s.membership != nil && !s.membership(serverID, session.ChannelID, userID) {
		s.sendErrorToUser(userID, session.ChannelID, req.SessionID, ErrWebRTCSignalingUnauthorized, "Usuário não está no mesmo canal da transmissão")
		return
	}

	// Não permite que o próprio broadcaster se junte como viewer
	if session.BroadcasterID == userID {
		return
	}

	// Adiciona o viewer atomicamente respeitando o limite
	ok, err := s.repo.AddViewerIfCapacity(ctx, req.SessionID, userID, s.config.MaxViewers)
	if err != nil || !ok {
		s.sendErrorToUser(userID, session.ChannelID, req.SessionID, ErrScreenShareViewerLimitReached, "Limite máximo de espectadores atingido para esta transmissão")
		return
	}

	// Resposta SCREEN_SHARE_JOINED para o viewer
	joinedPayload, _ := json.Marshal(&ScreenShareJoinedPayload{
		SessionID:     session.SessionID,
		ChannelID:     session.ChannelID,
		BroadcasterID: session.BroadcasterID,
		ViewerID:      userID,
		Quality:       session.Quality,
		StartedAt:     session.StartedAt,
	})
	_ = s.router.RouteToUser(userID, &WebRTCSignalingEvent{
		WebRTCSignalingRequest: WebRTCSignalingRequest{
			Type:      models.EventScreenShareJoined,
			ChannelID: session.ChannelID,
			SessionID: session.SessionID,
			SDP:       string(joinedPayload),
		},
		FromUserID: "system",
	})

	// Notificação SCREEN_SHARE_VIEWER_JOINED para o broadcaster (para iniciar o Offer)
	viewerJoinedPayload, _ := json.Marshal(&ScreenShareViewerJoinedPayload{
		SessionID: session.SessionID,
		ChannelID: session.ChannelID,
		ViewerID:  userID,
	})
	_ = s.router.RouteToUser(session.BroadcasterID, &WebRTCSignalingEvent{
		WebRTCSignalingRequest: WebRTCSignalingRequest{
			Type:      models.EventScreenShareViewerJoined,
			ChannelID: session.ChannelID,
			SessionID: session.SessionID,
			ToUserID:  session.BroadcasterID,
			SDP:       string(viewerJoinedPayload),
		},
		FromUserID: userID,
	})
}

// HandleStop encerra a transmissão (apenas autorizado para o broadcaster)
func (s *Service) HandleStop(ctx context.Context, userID, serverID string, req *WebRTCSignalingRequest) {
	if req.SessionID == "" {
		// Tenta encontrar por canal se não fornecido
		if req.ChannelID != "" {
			sess, _ := s.repo.GetByChannel(ctx, req.ChannelID)
			if sess != nil {
				req.SessionID = sess.SessionID
			}
		}
	}

	if req.SessionID == "" {
		return
	}

	session, err := s.repo.GetBySession(ctx, req.SessionID)
	if err != nil || session == nil {
		// Idempotência: já encerrada
		return
	}

	// Autoridade estrita: apenas o broadcaster pode encerrar
	if session.BroadcasterID != userID {
		s.sendErrorToUser(userID, session.ChannelID, req.SessionID, ErrScreenSharePermissionDenied, "Apenas o transmissor pode encerrar esta sessão")
		return
	}

	_ = s.repo.Delete(ctx, session.SessionID)

	stoppedPayload, _ := json.Marshal(&ScreenShareStoppedPayload{
		SessionID:     session.SessionID,
		ChannelID:     session.ChannelID,
		BroadcasterID: session.BroadcasterID,
	})

	_ = s.router.BroadcastToChannel(session.ChannelID, serverID, &models.WSEvent{
		Type:      models.EventScreenShareStopped,
		Payload:   stoppedPayload,
		ChannelID: session.ChannelID,
		ServerID:  serverID,
	})
}

// HandleSignaling repassa mensagens SDP Offer, SDP Answer e ICE Candidates
func (s *Service) HandleSignaling(ctx context.Context, userID, serverID string, req *WebRTCSignalingRequest) {
	if !s.rateLimiter.Allow(userID, req.Type) {
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingRateLimited, "Taxa de sinalização excedida")
		return
	}

	// Validação de limites de payload
	if len(req.SDP) > s.config.MaxSDPSize {
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingInvalidPayload, "SDP excede o tamanho máximo permitido")
		return
	}

	if req.Candidate != nil && len(req.Candidate.Candidate) > s.config.MaxCandidateSize {
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingInvalidPayload, "ICE Candidate excede o tamanho máximo permitido")
		return
	}

	// Validação de payload por tipo
	switch req.Type {
	case models.EventWebRTCOffer, models.EventWebRTCAnswer:
		if req.SDP == "" {
			s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingInvalidPayload, "SDP é obrigatório para Offer/Answer")
			return
		}
		if req.Candidate != nil {
			s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingInvalidPayload, "Candidate é proibido em Offer/Answer")
			return
		}
	case models.EventWebRTCICECandidate:
		if req.Candidate == nil || req.Candidate.Candidate == "" {
			s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingInvalidPayload, "Candidate é obrigatório")
			return
		}
	default:
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingInvalidPayload, "Tipo de evento de sinalização desconhecido")
		return
	}

	if req.SessionID == "" || req.ToUserID == "" {
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrWebRTCSignalingInvalidPayload, "session_id e to_user_id são obrigatórios")
		return
	}

	session, err := s.repo.GetBySession(ctx, req.SessionID)
	if err != nil || session == nil || session.State != SessionStateActive {
		s.sendErrorToUser(userID, req.ChannelID, req.SessionID, ErrScreenShareInvalidSession, "Sessão inválida ou inativa")
		return
	}

	// Validação Anti-BOLA: Remetente e Destinatário precisam estar no canal autoritativo da sessão
	if s.membership != nil {
		if !s.membership(serverID, session.ChannelID, userID) {
			s.sendErrorToUser(userID, session.ChannelID, req.SessionID, ErrWebRTCSignalingUnauthorized, "Remetente fora do canal da transmissão")
			return
		}
		if !s.membership(serverID, session.ChannelID, req.ToUserID) {
			s.sendErrorToUser(userID, session.ChannelID, req.SessionID, ErrScreenShareInvalidRecipient, "Destinatário fora do canal da transmissão")
			return
		}
	}

	// Repassa com FromUserID injetado de forma segura
	event := &WebRTCSignalingEvent{
		WebRTCSignalingRequest: *req,
		FromUserID:             userID,
	}
	event.ChannelID = session.ChannelID

	if err := s.router.RouteToUser(req.ToUserID, event); err != nil {
		log.Printf("[ScreenShareService] Erro ao rotear sinalização para %s: %v", req.ToUserID, err)
	}
}

// OnUserDisconnected trata a saída ou queda de conexão de um usuário
func (s *Service) OnUserDisconnected(ctx context.Context, userID, serverID string, isUserOnlineChecker func(uid string) bool) {
	// 1. Verifica se o usuário é broadcaster de alguma sessão
	// Como o repo pode ter poucas sessões simultâneas, podemos iterar ou verificar se houver mapa
	// Para o repo in-memory:
	if inMem, ok := s.repo.(*InMemoryScreenShareRepository); ok {
		inMem.mu.RLock()
		var broadcasterSessions []*ChannelScreenShareState
		var viewerSessions []*ChannelScreenShareState
		for _, sess := range inMem.bySessionID {
			if sess.State == SessionStateActive {
				if sess.BroadcasterID == userID {
					broadcasterSessions = append(broadcasterSessions, inMem.copyState(sess))
				} else if _, isViewer := sess.ViewerUserIDs[userID]; isViewer {
					viewerSessions = append(viewerSessions, inMem.copyState(sess))
				}
			}
		}
		inMem.mu.RUnlock()

		// Trata viewers que desconectaram
		for _, vs := range viewerSessions {
			_ = s.repo.RemoveViewer(ctx, vs.SessionID, userID)
			vLeftPayload, _ := json.Marshal(&ScreenShareViewerLeftPayload{
				SessionID: vs.SessionID,
				ChannelID: vs.ChannelID,
				ViewerID:  userID,
			})
			_ = s.router.RouteToUser(vs.BroadcasterID, &WebRTCSignalingEvent{
				WebRTCSignalingRequest: WebRTCSignalingRequest{
					Type:      models.EventScreenShareViewerLeft,
					ChannelID: vs.ChannelID,
					SessionID: vs.SessionID,
					ToUserID:  vs.BroadcasterID,
					SDP:       string(vLeftPayload),
				},
				FromUserID: userID,
			})
		}

		// Trata broadcasters com Grace Period seguro
		for _, bs := range broadcasterSessions {
			graceUntil := time.Now().Add(s.config.GracePeriod)
			_ = s.repo.SetGracePeriod(ctx, bs.SessionID, &graceUntil)

			// Dispara verificação após o grace period
			go func(sessionID, channelID, bID string, targetGrace time.Time) {
				time.Sleep(s.config.GracePeriod + 100*time.Millisecond)

				curSess, err := s.repo.GetBySession(context.Background(), sessionID)
				if err != nil || curSess == nil || curSess.State != SessionStateActive {
					return
				}

				// Se o grace period foi cancelado (broadcaster reconectou)
				if curSess.GraceUntil == nil {
					return
				}

				// Se o broadcaster voltou a ficar online
				if isUserOnlineChecker != nil && isUserOnlineChecker(bID) {
					_ = s.repo.SetGracePeriod(context.Background(), sessionID, nil)
					return
				}

				// Se o tempo expirou de fato, encerra a transmissão
				if time.Now().After(targetGrace) {
					log.Printf("[ScreenShareService] Grace period expirado para broadcaster %s na sessão %s. Encerrando.", bID, sessionID)
					_ = s.repo.Delete(context.Background(), sessionID)

					stoppedPayload, _ := json.Marshal(&ScreenShareStoppedPayload{
						SessionID:     sessionID,
						ChannelID:     channelID,
						BroadcasterID: bID,
					})
					_ = s.router.BroadcastToChannel(channelID, serverID, &models.WSEvent{
						Type:      models.EventScreenShareStopped,
						Payload:   stoppedPayload,
						ChannelID: channelID,
						ServerID:  serverID,
					})
				}
			}(bs.SessionID, bs.ChannelID, bs.BroadcasterID, graceUntil)
		}
	}
}

func errorsIs(err, target error) bool {
	return err == target
}
