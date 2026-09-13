package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	repo       repository.Repository
	jwtService *auth.JWTService
}

func NewAuthHandler(repo repository.Repository, jwtService *auth.JWTService) *AuthHandler {
	return &AuthHandler{
		repo:       repo,
		jwtService: jwtService,
	}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req models.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Email == "" || req.Password == "" || req.Username == "" {
		http.Error(w, `{"error":"Parâmetros inválidos (username, email e password são obrigatórios)"}`, http.StatusBadRequest)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, `{"error":"Erro ao processar senha"}`, http.StatusInternalServerError)
		return
	}

	user := &models.User{
		Username:  req.Username,
		Email:     req.Email,
		Password:  string(hashedPassword),
		AvatarURL: "https://api.dicebear.com/7.x/bottts/svg?seed=" + req.Username,
		Status:    "online",
	}

	if err := h.repo.CreateUser(user); err != nil {
		if err == repository.ErrAlreadyExists {
			http.Error(w, `{"error":"Email já cadastrado"}`, http.StatusConflict)
			return
		}
		http.Error(w, `{"error":"Erro ao criar usuário"}`, http.StatusInternalServerError)
		return
	}

	token, err := h.jwtService.GenerateToken(user)
	if err != nil {
		http.Error(w, `{"error":"Erro ao gerar token"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(models.AuthResponse{
		Token: token,
		User:  user,
	})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Email == "" || req.Password == "" {
		http.Error(w, `{"error":"Email e senha são obrigatórios"}`, http.StatusBadRequest)
		return
	}

	user, err := h.repo.GetUserByEmail(req.Email)
	if err != nil {
		http.Error(w, `{"error":"Credenciais inválidas"}`, http.StatusUnauthorized)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		http.Error(w, `{"error":"Credenciais inválidas"}`, http.StatusUnauthorized)
		return
	}

	token, err := h.jwtService.GenerateToken(user)
	if err != nil {
		http.Error(w, `{"error":"Erro ao gerar token"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(models.AuthResponse{
		Token: token,
		User:  user,
	})
}

func (h *AuthHandler) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value("user_id").(string)
	if !ok || userID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	user, err := h.repo.GetUserByID(userID)
	if err != nil {
		http.Error(w, `{"error":"Usuário não encontrado"}`, http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}
