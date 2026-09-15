package auth

import (
	"testing"
)

func TestLiveKitService_GenerateVoiceToken(t *testing.T) {
	apiKey := "devkey"
	apiSecret := "secret123456789012345678901234567890"

	service := NewLiveKitService(apiKey, apiSecret)
	if service == nil {
		t.Fatal("Expected non-nil LiveKitService")
	}

	token, err := service.GenerateVoiceToken("lounge-room", "usr_100", "Alice")
	if err != nil {
		t.Fatalf("GenerateVoiceToken failed: %v", err)
	}
	if token == "" {
		t.Fatal("Expected non-empty LiveKit token")
	}
}
