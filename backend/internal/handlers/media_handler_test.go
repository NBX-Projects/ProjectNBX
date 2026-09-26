package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/storage"
)

func createValidPNGBuffer() *bytes.Buffer {
	// Magic bytes de um PNG válido: 89 50 4E 47 0D 0A 1A 0A
	buf := &bytes.Buffer{}
	buf.Write([]byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52})
	buf.Write(bytes.Repeat([]byte{0x00}, 500))
	return buf
}

func TestUploadMedia_Unauthorized(t *testing.T) {
	storageMock := storage.NewLocalStorageService(t.TempDir(), "http://localhost:8080")
	repo := repository.NewMemoryRepository()
	handler := NewMediaHandler(storageMock, repo)

	req := httptest.NewRequest(http.MethodPost, "/api/media/upload", nil)
	w := httptest.NewRecorder()

	handler.UploadMedia(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("Esperava status 401 Unauthorized, obteve %d", w.Code)
	}
}

func TestUploadMedia_ValidPNG(t *testing.T) {
	storageMock := storage.NewLocalStorageService(t.TempDir(), "http://localhost:8080")
	repo := repository.NewMemoryRepository()
	handler := NewMediaHandler(storageMock, repo)

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", "avatar.png")
	if err != nil {
		t.Fatalf("Erro ao criar form file: %v", err)
	}
	_, _ = io.Copy(part, createValidPNGBuffer())
	_ = writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/media/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	// Injeta usuário autenticado no contexto
	ctx := auth.WithUserContext(context.Background(), "user_test_123", "testuser")
	req = req.WithContext(ctx)

	w := httptest.NewRecorder()
	handler.UploadMedia(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Esperava status 200 OK, obteve %d. Body: %s", w.Code, w.Body.String())
	}

	var resp UploadMediaResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("Falha ao decodificar resposta JSON: %v", err)
	}

	if resp.URL == "" {
		t.Errorf("URL retornada não deveria ser vazia")
	}
	if resp.MediaType != "image/png" {
		t.Errorf("MediaType esperado image/png, obteve %s", resp.MediaType)
	}
}

func TestUploadMedia_InvalidFormat(t *testing.T) {
	storageMock := storage.NewLocalStorageService(t.TempDir(), "http://localhost:8080")
	repo := repository.NewMemoryRepository()
	handler := NewMediaHandler(storageMock, repo)

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", "script.sh")
	if err != nil {
		t.Fatalf("Erro ao criar form file: %v", err)
	}
	_, _ = part.Write([]byte("#!/bin/bash\necho 'malicious'"))
	_ = writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/media/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	ctx := auth.WithUserContext(context.Background(), "user_test_123", "testuser")
	req = req.WithContext(ctx)

	w := httptest.NewRecorder()
	handler.UploadMedia(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("Esperava status 400 Bad Request para formato inválido, obteve %d", w.Code)
	}
}

func TestUploadMedia_ExceedsMaxSize(t *testing.T) {
	storageMock := storage.NewLocalStorageService(t.TempDir(), "http://localhost:8080")
	repo := repository.NewMemoryRepository()
	handler := NewMediaHandler(storageMock, repo)

	// Cria arquivo maior que 5 MB (5 * 1024 * 1024 + 512 bytes)
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", "huge.png")
	if err != nil {
		t.Fatalf("Erro ao criar form file: %v", err)
	}
	// Escreve magic bytes de PNG
	_, _ = part.Write([]byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A})
	// Escreve mais de 5MB
	hugeData := bytes.Repeat([]byte{0x00}, (5<<20)+1024)
	_, _ = part.Write(hugeData)
	_ = writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/media/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	ctx := auth.WithUserContext(context.Background(), "user_test_123", "testuser")
	req = req.WithContext(ctx)

	w := httptest.NewRecorder()
	handler.UploadMedia(w, req)

	if w.Code != http.StatusRequestEntityTooLarge {
		t.Errorf("Esperava status 413 Payload Too Large para arquivo > 5MB, obteve %d", w.Code)
	}

	var resp map[string]string
	_ = json.NewDecoder(w.Body).Decode(&resp)
	if resp["error"] != "Arquivo excede o tamanho máximo permitido de 5 MB" {
		t.Errorf("Mensagem de erro inesperada: %v", resp["error"])
	}
}


