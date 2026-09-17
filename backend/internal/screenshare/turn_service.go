package screenshare

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"fmt"
	"time"
)

type TURNCredentialsResponse struct {
	URLs       []string `json:"urls"`
	Username   string   `json:"username"`
	Credential string   `json:"credential"`
	ExpiresAt  int64    `json:"expires_at"`
	TTLSeconds int64    `json:"ttl_seconds"`
}

type TURNService struct {
	config TURNConfig
}

func NewTURNService(config TURNConfig) *TURNService {
	return &TURNService{
		config: config,
	}
}

// GenerateCredentials gera credenciais temporárias HMAC-SHA1 de acordo com o RFC 5766 REST API
func (s *TURNService) GenerateCredentials(userID string) (*TURNCredentialsResponse, error) {
	if !s.config.Enabled || s.config.Secret == "" || len(s.config.URLs) == 0 {
		return &TURNCredentialsResponse{
			URLs:       []string{},
			Username:   "",
			Credential: "",
			ExpiresAt:  0,
			TTLSeconds: 0,
		}, nil
	}

	ttl := s.config.CredentialTTL
	if ttl <= 0 {
		ttl = 1 * time.Hour
	}

	expiry := time.Now().Add(ttl).Unix()
	username := fmt.Sprintf("%d:%s", expiry, userID)

	mac := hmac.New(sha1.New, []byte(s.config.Secret))
	mac.Write([]byte(username))
	credential := base64.StdEncoding.EncodeToString(mac.Sum(nil))

	return &TURNCredentialsResponse{
		URLs:       s.config.URLs,
		Username:   username,
		Credential: credential,
		ExpiresAt:  expiry,
		TTLSeconds: int64(ttl.Seconds()),
	}, nil
}
