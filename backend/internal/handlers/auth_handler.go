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

	name := req.Name
	if name == "" {
		name = req.Username
	}

	user := &models.User{
		Name:      name,
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

	// Registrar Auditoria
	_ = h.repo.CreateAuditLog(&models.AuditLog{
		Source:     models.AuditSourceAuth,
		Action:     "USER_REGISTER",
		UserID:     &user.ID,
		ResourceID: &user.ID,
		IPAddress:  r.RemoteAddr,
		UserAgent:  r.UserAgent(),
		Metadata: map[string]interface{}{
			"email":    user.Email,
			"username": user.Username,
		},
	})

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
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Corpo da requisição inválido"}`, http.StatusBadRequest)
		return
	}

	loginIdentifier := req.Login
	if loginIdentifier == "" {
		loginIdentifier = req.Email
	}

	if loginIdentifier == "" || req.Password == "" {
		http.Error(w, `{"error":"Email/usuário e senha são obrigatórios"}`, http.StatusBadRequest)
		return
	}

	user, err := h.repo.GetUserByEmailOrUsername(loginIdentifier)
	if err != nil {
		// Log de auditoria para tentativa falha
		_ = h.repo.CreateAuditLog(&models.AuditLog{
			Source:    models.AuditSourceAuth,
			Action:    "USER_LOGIN_FAILED",
			IPAddress: r.RemoteAddr,
			UserAgent: r.UserAgent(),
			Metadata: map[string]interface{}{
				"login":  loginIdentifier,
				"reason": "user_not_found",
			},
		})

		http.Error(w, `{"error":"Credenciais inválidas"}`, http.StatusUnauthorized)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		// Log de auditoria para senha incorreta
		_ = h.repo.CreateAuditLog(&models.AuditLog{
			Source:    models.AuditSourceAuth,
			Action:    "USER_LOGIN_FAILED",
			UserID:    &user.ID,
			IPAddress: r.RemoteAddr,
			UserAgent: r.UserAgent(),
			Metadata: map[string]interface{}{
				"login":  loginIdentifier,
				"reason": "invalid_password",
			},
		})

		http.Error(w, `{"error":"Credenciais inválidas"}`, http.StatusUnauthorized)
		return
	}

	token, err := h.jwtService.GenerateToken(user)
	if err != nil {
		http.Error(w, `{"error":"Erro ao gerar token"}`, http.StatusInternalServerError)
		return
	}

	// Registrar Auditoria de Login com Sucesso
	_ = h.repo.CreateAuditLog(&models.AuditLog{
		Source:     models.AuditSourceAuth,
		Action:     "USER_LOGIN_SUCCESS",
		UserID:     &user.ID,
		ResourceID: &user.ID,
		IPAddress:  r.RemoteAddr,
		UserAgent:  r.UserAgent(),
		Metadata: map[string]interface{}{
			"login": loginIdentifier,
		},
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(models.AuthResponse{
		Token: token,
		User:  user,
	})
}

func (h *AuthHandler) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserID(r.Context())
	if userID == "" {
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

func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	var req models.UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Dados inválidos"}`, http.StatusBadRequest)
		return
	}

	existingUser, err := h.repo.GetUserByID(userID)
	if err != nil {
		http.Error(w, `{"error":"Usuário não encontrado"}`, http.StatusNotFound)
		return
	}

	if req.Name != "" {
		existingUser.Name = req.Name
	}
	if req.Username != "" {
		existingUser.Username = req.Username
	}
	if req.Email != "" {
		existingUser.Email = req.Email
	}

	if err := h.repo.UpdateUser(existingUser); err != nil {
		if err == repository.ErrAlreadyExists {
			http.Error(w, `{"error":"Nome de usuário ou e-mail já está em uso"}`, http.StatusConflict)
			return
		}
		http.Error(w, `{"error":"Erro ao atualizar perfil"}`, http.StatusInternalServerError)
		return
	}

	_ = h.repo.CreateAuditLog(&models.AuditLog{
		Source:     models.AuditSourceUser,
		Action:     "USER_PROFILE_UPDATED",
		UserID:     &userID,
		ResourceID: &userID,
		IPAddress:  r.RemoteAddr,
		UserAgent:  r.UserAgent(),
		Metadata: map[string]interface{}{
			"name":     existingUser.Name,
			"username": existingUser.Username,
			"email":    existingUser.Email,
		},
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(existingUser)
}

func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	userID := auth.GetUserID(r.Context())
	if userID == "" {
		http.Error(w, `{"error":"Não autorizado"}`, http.StatusUnauthorized)
		return
	}

	var req models.ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.CurrentPassword == "" || req.NewPassword == "" {
		http.Error(w, `{"error":"Senha atual e nova senha são obrigatórias"}`, http.StatusBadRequest)
		return
	}

	if len(req.NewPassword) < 6 {
		http.Error(w, `{"error":"A nova senha deve ter no mínimo 6 caracteres"}`, http.StatusBadRequest)
		return
	}

	user, err := h.repo.GetUserByID(userID)
	if err != nil {
		http.Error(w, `{"error":"Usuário não encontrado"}`, http.StatusNotFound)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.CurrentPassword)); err != nil {
		http.Error(w, `{"error":"Senha atual incorreta"}`, http.StatusUnauthorized)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, `{"error":"Erro ao processar nova senha"}`, http.StatusInternalServerError)
		return
	}

	if err := h.repo.UpdateUserPassword(userID, string(hashedPassword)); err != nil {
		http.Error(w, `{"error":"Erro ao atualizar senha"}`, http.StatusInternalServerError)
		return
	}

	_ = h.repo.CreateAuditLog(&models.AuditLog{
		Source:     models.AuditSourceAuth,
		Action:     "USER_PASSWORD_CHANGED",
		UserID:     &userID,
		ResourceID: &userID,
		IPAddress:  r.RemoteAddr,
		UserAgent:  r.UserAgent(),
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Senha alterada com sucesso"})
}

func (h *AuthHandler) SearchUsers(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode([]*models.User{})
		return
	}

	users, err := h.repo.SearchUsers(query, 10)
	if err != nil {
		http.Error(w, `{"error":"Erro ao pesquisar usuários"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

