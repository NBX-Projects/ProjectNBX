package screenshare

import (
	"github.com/projectnbx/backend/internal/models"
)

// SignalingRouter abstrai o roteamento de mensagens de sinalização
type SignalingRouter interface {
	RouteToUser(userID string, event *WebRTCSignalingEvent) error
	BroadcastToChannel(channelID, serverID string, event *models.WSEvent) error
}
