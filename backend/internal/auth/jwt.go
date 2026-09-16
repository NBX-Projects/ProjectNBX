package auth

import (
	"context"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/projectnbx/backend/internal/models"
)

type contextKey string

const (
	contextKeyUserID   contextKey = "user_id"
	contextKeyUsername contextKey = "username"
)

// WithUserContext adiciona userID e username tipados ao context
func WithUserContext(ctx context.Context, userID, username string) context.Context {
	ctx = context.WithValue(ctx, contextKeyUserID, userID)
	return context.WithValue(ctx, contextKeyUsername, username)
}

// GetUserID extrai o userID do context com fallback para retrocompatibilidade
func GetUserID(ctx context.Context) string {
	if ctx == nil {
		return ""
	}
	if id, ok := ctx.Value(contextKeyUserID).(string); ok && id != "" {
		return id
	}
	if id, ok := ctx.Value("user_id").(string); ok {
		return id
	}
	return ""
}

// GetUsername extrai o username do context com fallback para retrocompatibilidade
func GetUsername(ctx context.Context) string {
	if ctx == nil {
		return ""
	}
	if u, ok := ctx.Value(contextKeyUsername).(string); ok && u != "" {
		return u
	}
	if u, ok := ctx.Value("username").(string); ok {
		return u
	}
	return ""
}

type JWTService struct {
	secretKey []byte
}

type Claims struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	jwt.RegisteredClaims
}

func NewJWTService(secret string) *JWTService {
	return &JWTService{secretKey: []byte(secret)}
}

// GenerateToken cria um novo JWT assinado com validade de 7 dias
func (j *JWTService) GenerateToken(user *models.User) (string, error) {
	claims := Claims{
		UserID:   user.ID,
		Username: user.Username,
		Email:    user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(7 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "ProjectNBX-Auth",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(j.secretKey)
}

// ValidateToken valida e extrai os claims do JWT
func (j *JWTService) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("método de assinatura inválido")
		}
		return j.secretKey, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("token inválido")
}
