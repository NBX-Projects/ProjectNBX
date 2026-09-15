package auth

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/projectnbx/backend/internal/models"
)

func TestJWTService_GenerateAndValidate(t *testing.T) {
	secret := "super-secret-key-12345"
	service := NewJWTService(secret)

	user := &models.User{
		ID:       "usr_100",
		Username: "TestUser",
		Email:    "test@example.com",
	}

	token, err := service.GenerateToken(user)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}
	if token == "" {
		t.Fatal("Expected non-empty token string")
	}

	claims, err := service.ValidateToken(token)
	if err != nil {
		t.Fatalf("ValidateToken failed: %v", err)
	}
	if claims.UserID != user.ID {
		t.Errorf("Expected UserID %s, got %s", user.ID, claims.UserID)
	}
	if claims.Username != user.Username {
		t.Errorf("Expected Username %s, got %s", user.Username, claims.Username)
	}
	if claims.Email != user.Email {
		t.Errorf("Expected Email %s, got %s", user.Email, claims.Email)
	}
}

func TestJWTService_InvalidToken(t *testing.T) {
	service := NewJWTService("correct-secret")

	// Invalid token string
	_, err := service.ValidateToken("invalid.token.string")
	if err == nil {
		t.Error("Expected error for invalid token string")
	}

	// Token signed with different secret
	otherService := NewJWTService("wrong-secret")
	user := &models.User{ID: "usr_100", Username: "Test", Email: "t@e.com"}
	token, _ := otherService.GenerateToken(user)

	_, err = service.ValidateToken(token)
	if err == nil {
		t.Error("Expected error when validating token signed with wrong secret")
	}

	// Token with None algorithm / invalid signing method
	claims := Claims{
		UserID: "usr_100",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
		},
	}
	noneToken := jwt.NewWithClaims(jwt.SigningMethodNone, claims)
	tokenStr, _ := noneToken.SignedString(jwt.UnsafeAllowNoneSignatureType)
	_, err = service.ValidateToken(tokenStr)
	if err == nil {
		t.Error("Expected error for None signing method")
	}
}
