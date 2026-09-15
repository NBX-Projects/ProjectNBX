package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
)

func setupAuthTest() (*AuthHandler, *repository.MemoryRepository, *auth.JWTService) {
	repo := repository.NewMemoryRepository()
	jwtService := auth.NewJWTService("test_jwt_secret_key_123")
	handler := NewAuthHandler(repo, jwtService)
	return handler, repo, jwtService
}

func TestAuthHandler_Register(t *testing.T) {
	handler, _, _ := setupAuthTest()

	// 1. Success
	body, _ := json.Marshal(map[string]string{
		"username": "tester",
		"email":    "tester@example.com",
		"password": "password123",
	})
	req := httptest.NewRequest("POST", "/api/auth/register", bytes.NewReader(body))
	rr := httptest.NewRecorder()
	handler.Register(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created, got %d: %s", rr.Code, rr.Body.String())
	}

	// 2. Duplicate email
	reqDup := httptest.NewRequest("POST", "/api/auth/register", bytes.NewReader(body))
	rrDup := httptest.NewRecorder()
	handler.Register(rrDup, reqDup)

	if rrDup.Code != http.StatusConflict {
		t.Errorf("Expected 409 Conflict for duplicate email, got %d", rrDup.Code)
	}

	// 3. Invalid payload
	reqInvalid := httptest.NewRequest("POST", "/api/auth/register", bytes.NewReader([]byte(`{"username":""}`)))
	rrInvalid := httptest.NewRecorder()
	handler.Register(rrInvalid, reqInvalid)

	if rrInvalid.Code != http.StatusBadRequest {
		t.Errorf("Expected 400 Bad Request, got %d", rrInvalid.Code)
	}
}

func TestAuthHandler_Login(t *testing.T) {
	handler, _, _ := setupAuthTest()

	// 1. Success with seed user (dev@projectnbx.com / admin123)
	body, _ := json.Marshal(map[string]string{
		"email":    "dev@projectnbx.com",
		"password": "admin123",
	})
	req := httptest.NewRequest("POST", "/api/auth/login", bytes.NewReader(body))
	rr := httptest.NewRecorder()
	handler.Login(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d: %s", rr.Code, rr.Body.String())
	}

	var resp models.AuthResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil || resp.Token == "" {
		t.Errorf("Expected non-empty token in login response")
	}

	// 2. Incorrect password
	badPassBody, _ := json.Marshal(map[string]string{
		"email":    "dev@projectnbx.com",
		"password": "wrong_password",
	})
	reqBadPass := httptest.NewRequest("POST", "/api/auth/login", bytes.NewReader(badPassBody))
	rrBadPass := httptest.NewRecorder()
	handler.Login(rrBadPass, reqBadPass)

	if rrBadPass.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized for bad password, got %d", rrBadPass.Code)
	}

	// 3. User not found
	missingBody, _ := json.Marshal(map[string]string{
		"email":    "nonexistent@example.com",
		"password": "password123",
	})
	reqMissing := httptest.NewRequest("POST", "/api/auth/login", bytes.NewReader(missingBody))
	rrMissing := httptest.NewRecorder()
	handler.Login(rrMissing, reqMissing)

	if rrMissing.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized for non-existent user, got %d", rrMissing.Code)
	}

	// 4. Invalid payload
	reqInvalid := httptest.NewRequest("POST", "/api/auth/login", bytes.NewReader([]byte(`{"bad": "json"}`)))
	rrInvalid := httptest.NewRecorder()
	handler.Login(rrInvalid, reqInvalid)

	if rrInvalid.Code != http.StatusBadRequest {
		t.Errorf("Expected 400 Bad Request, got %d", rrInvalid.Code)
	}
}

func TestAuthHandler_Me(t *testing.T) {
	handler, _, _ := setupAuthTest()

	// 1. Authenticated
	req := newAuthRequest("GET", "/api/auth/me", nil, "usr_dev_1", nil)
	rr := httptest.NewRecorder()
	handler.GetCurrentUser(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected 200 OK, got %d", rr.Code)
	}

	// 2. Unauthenticated (no user_id in ctx)
	reqUnauth := httptest.NewRequest("GET", "/api/auth/me", nil)
	rrUnauth := httptest.NewRecorder()
	handler.GetCurrentUser(rrUnauth, reqUnauth)

	if rrUnauth.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized, got %d", rrUnauth.Code)
	}

	// 3. User in ctx not found in DB
	reqNotFound := newAuthRequest("GET", "/api/auth/me", nil, "usr_not_in_db", nil)
	rrNotFound := httptest.NewRecorder()
	handler.GetCurrentUser(rrNotFound, reqNotFound)

	if rrNotFound.Code != http.StatusNotFound {
		t.Errorf("Expected 404 Not Found, got %d", rrNotFound.Code)
	}
}

func TestAuthHandler_SearchUsers(t *testing.T) {
	handler, _, _ := setupAuthTest()

	req := httptest.NewRequest("GET", "/api/users/search?q=Dark", nil)
	rr := httptest.NewRecorder()
	handler.SearchUsers(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected 200 OK, got %d", rr.Code)
	}
}
