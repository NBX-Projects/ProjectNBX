package auth

import (
	"time"

	lkauth "github.com/livekit/protocol/auth"
)

type LiveKitService struct {
	apiKey    string
	apiSecret string
}

func NewLiveKitService(apiKey, apiSecret string) *LiveKitService {
	return &LiveKitService{
		apiKey:    apiKey,
		apiSecret: apiSecret,
	}
}

// GenerateVoiceToken gera um token de acesso LiveKit assinado com VideoGrant
func (s *LiveKitService) GenerateVoiceToken(roomName, identity, name string) (string, error) {
	at := lkauth.NewAccessToken(s.apiKey, s.apiSecret)

	canPublish := true
	canSubscribe := true
	canPublishData := true

	grant := &lkauth.VideoGrant{
		RoomJoin:       true,
		Room:           roomName,
		CanPublish:     &canPublish,
		CanSubscribe:   &canSubscribe,
		CanPublishData: &canPublishData,
	}

	at.AddGrant(grant).
		SetIdentity(identity).
		SetName(name).
		SetValidFor(24 * time.Hour)

	return at.ToJWT()
}
