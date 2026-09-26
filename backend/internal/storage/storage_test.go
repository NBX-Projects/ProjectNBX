package storage

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/projectnbx/backend/config"
)

func TestLocalStorageService(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "nbx_uploads_test_*")
	if err != nil {
		t.Fatalf("Erro ao criar temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	storage := NewLocalStorageService(tempDir, "http://localhost:8080")

	data := []byte("fake image data")
	filename := "test_image.png"

	url, err := storage.Upload(context.Background(), bytes.NewReader(data), filename, "image/png")
	if err != nil {
		t.Fatalf("Upload falhou: %v", err)
	}

	expectedURL := "http://localhost:8080/uploads/" + filename
	if url != expectedURL {
		t.Errorf("URL esperada %s, obtida %s", expectedURL, url)
	}

	// Verifica se o arquivo foi realmente criado no disco
	savedPath := filepath.Join(tempDir, filename)
	if _, err := os.Stat(savedPath); os.IsNotExist(err) {
		t.Errorf("Arquivo não foi encontrado no disco em %s", savedPath)
	}

	// Testa remoção
	if err := storage.Delete(context.Background(), filename); err != nil {
		t.Errorf("Erro ao deletar arquivo: %v", err)
	}

	if _, err := os.Stat(savedPath); !os.IsNotExist(err) {
		t.Errorf("Arquivo ainda existe após deleção")
	}
}

func TestNewStorageServiceFallback(t *testing.T) {
	cfg := &config.Config{
		UploadsDir:    "temp_uploads",
		PublicBaseURL: "http://localhost:8080",
	}

	svc := NewStorageService(cfg)
	if _, ok := svc.(*LocalStorageService); !ok {
		t.Errorf("Esperava LocalStorageService como fallback padrão")
	}
}

func TestExtractCloudinaryPublicID(t *testing.T) {
	tests := []struct {
		name       string
		identifier string
		folder     string
		expected   string
	}{
		{
			name:       "Standard secure URL with version",
			identifier: "https://res.cloudinary.com/n2srrzcg/image/upload/v1727061313/projectnbx/img_fa12345.jpg",
			folder:     "projectnbx",
			expected:   "projectnbx/img_fa12345",
		},
		{
			name:       "Transformed secure URL with f_auto and version",
			identifier: "https://res.cloudinary.com/n2srrzcg/image/upload/f_auto,q_auto:good/v1727061313/projectnbx/img_fa12345.png",
			folder:     "projectnbx",
			expected:   "projectnbx/img_fa12345",
		},
		{
			name:       "Filename only with extension",
			identifier: "img_fa12345.jpg",
			folder:     "projectnbx",
			expected:   "projectnbx/img_fa12345",
		},
		{
			name:       "Full public_id without extension",
			identifier: "projectnbx/img_fa12345",
			folder:     "projectnbx",
			expected:   "projectnbx/img_fa12345",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractCloudinaryPublicID(tt.identifier, tt.folder)
			if got != tt.expected {
				t.Errorf("extractCloudinaryPublicID() = %v, esperado %v", got, tt.expected)
			}
		})
	}
}

