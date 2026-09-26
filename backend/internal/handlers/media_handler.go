package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/projectnbx/backend/internal/auth"
	"github.com/projectnbx/backend/internal/models"
	"github.com/projectnbx/backend/internal/repository"
	"github.com/projectnbx/backend/internal/storage"
)

// MediaHandler gerencia uploads e gerenciamento de arquivos de mídia
type MediaHandler struct {
	storage storage.StorageService
	repo    repository.Repository
}

func NewMediaHandler(storage storage.StorageService, repo repository.Repository) *MediaHandler {
	return &MediaHandler{
		storage: storage,
		repo:    repo,
	}
}

// UploadMediaResponse payload de resposta do upload de imagem
type UploadMediaResponse struct {
	URL       string `json:"url"`
	Filename  string `json:"filename"`
	MediaType string `json:"media_type"`
	Size      int64  `json:"size"`
}

var allowedMimeTypes = map[string]string{
	"image/jpeg": ".jpg",
	"image/jpg":  ".jpg",
	"image/png":  ".png",
	"image/gif":  ".gif",
	"image/webp": ".webp",
	"image/bmp":  ".bmp",
}

const maxUploadSize = 5 << 20 // 5 MB (5 * 1024 * 1024 = 5.242.880 bytes)

// UploadMedia recebe um arquivo multipart/form-data, valida magic bytes e formato, e armazena via StorageService
func (h *MediaHandler) UploadMedia(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	userID := auth.GetUserID(r.Context())
	if userID == "" {
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(map[string]string{"error": "Não autenticado"})
		return
	}

	// 1. Limita o tamanho máximo lido para prevenir saturação de memória (Anti-DoS)
	r.Body = http.MaxBytesReader(w, r.Body, maxUploadSize)

	if err := r.ParseMultipartForm(maxUploadSize); err != nil {
		w.WriteHeader(http.StatusRequestEntityTooLarge)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error": "Arquivo excede o tamanho máximo permitido de 5 MB",
		})
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{"error": "Campo 'file' obrigatório"})
		return
	}
	defer file.Close()

	if header.Size > maxUploadSize {
		w.WriteHeader(http.StatusRequestEntityTooLarge)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error": "Arquivo excede o tamanho máximo permitido de 5 MB",
		})
		return
	}

	// 2. Validação estrita por Magic Bytes (lê os primeiros 512 bytes)
	buffer := make([]byte, 512)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(map[string]string{"error": "Falha ao ler cabeçalho do arquivo"})
		return
	}

	detectedMime := http.DetectContentType(buffer[:n])
	// Limpa parâmetros adicionais do MIME (ex: text/plain; charset=utf-8)
	detectedMime = strings.Split(detectedMime, ";")[0]
	detectedMime = strings.TrimSpace(detectedMime)

	ext, isAllowed := allowedMimeTypes[detectedMime]
	if !isAllowed {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error": fmt.Sprintf("Formato inválido (%s). Formatos permitidos: PNG, JPG, GIF, WEBP e BMP", detectedMime),
		})
		return
	}

	// Recombina o buffer lido com o restante do arquivo
	fullStream := io.MultiReader(bytes.NewReader(buffer[:n]), file)

	// 3. Gera nome de arquivo criptograficamente único para evitar colisão e Path Traversal
	uniqueFilename := fmt.Sprintf("img_%s%s", uuid.New().String(), ext)

	// 4. Executa upload via StorageService (Cloudinary ou Local)
	publicURL, err := h.storage.Upload(r.Context(), fullStream, uniqueFilename, detectedMime)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"error": fmt.Sprintf("Erro ao armazenar imagem: %v", err),
		})
		return
	}

	// 5. Registro de auditoria
	if h.repo != nil {
		_ = h.repo.CreateAuditLog(&models.AuditLog{
			ID:        "aud_" + uuid.New().String(),
			UserID:    &userID,
			Action:    "UPLOAD_IMAGE",
			Source:    models.AuditSourceChat,
			IPAddress: r.RemoteAddr,
			UserAgent: r.UserAgent(),
			Metadata: map[string]interface{}{
				"filename":   uniqueFilename,
				"mime_type":  detectedMime,
				"size_bytes": header.Size,
				"url":        publicURL,
			},
			CreatedAt: time.Now(),
		})
	}

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(UploadMediaResponse{
		URL:       publicURL,
		Filename:  uniqueFilename,
		MediaType: detectedMime,
		Size:      header.Size,
	})
}
