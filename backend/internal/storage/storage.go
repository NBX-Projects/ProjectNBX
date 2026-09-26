package storage

import (
	"bytes"
	"context"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/projectnbx/backend/config"
)

// StorageService define o contrato abstrato para armazenamento de mídia
type StorageService interface {
	Upload(ctx context.Context, file io.Reader, filename string, mimeType string) (string, error)
	Delete(ctx context.Context, identifier string) error
}

// LocalStorageService armazena arquivos no sistema de arquivos local
type LocalStorageService struct {
	uploadsDir string
	baseURL    string
}

func NewLocalStorageService(uploadsDir, baseURL string) *LocalStorageService {
	if uploadsDir == "" {
		uploadsDir = "uploads"
	}
	_ = os.MkdirAll(uploadsDir, 0755)
	return &LocalStorageService{
		uploadsDir: uploadsDir,
		baseURL:    strings.TrimRight(baseURL, "/"),
	}
}

func (s *LocalStorageService) Upload(ctx context.Context, file io.Reader, filename string, mimeType string) (string, error) {
	if err := os.MkdirAll(s.uploadsDir, 0755); err != nil {
		return "", fmt.Errorf("falha ao criar diretório de uploads: %w", err)
	}

	dstPath := filepath.Join(s.uploadsDir, filename)
	dst, err := os.Create(dstPath)
	if err != nil {
		return "", fmt.Errorf("falha ao criar arquivo local: %w", err)
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		return "", fmt.Errorf("falha ao gravar dados no arquivo local: %w", err)
	}

	publicURL := fmt.Sprintf("%s/uploads/%s", s.baseURL, filename)
	return publicURL, nil
}

func (s *LocalStorageService) Delete(ctx context.Context, identifier string) error {
	filename := filepath.Base(identifier)
	target := filepath.Join(s.uploadsDir, filename)
	if err := os.Remove(target); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}

// CloudinaryStorageService armazena arquivos na nuvem do Cloudinary via REST API oficial
type CloudinaryStorageService struct {
	cloudName string
	apiKey    string
	apiSecret string
	folder    string
	client    *http.Client
}

func NewCloudinaryStorageService(cloudName, apiKey, apiSecret, folder string) *CloudinaryStorageService {
	if folder == "" {
		folder = "projectnbx"
	}
	return &CloudinaryStorageService{
		cloudName: cloudName,
		apiKey:    apiKey,
		apiSecret: apiSecret,
		folder:    folder,
		client:    &http.Client{Timeout: 30 * time.Second},
	}
}

type cloudinaryUploadResponse struct {
	SecureURL string `json:"secure_url"`
	PublicID  string `json:"public_id"`
	Error     *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

func (s *CloudinaryStorageService) generateSignature(params map[string]string) string {
	keys := make([]string, 0, len(params))
	for k := range params {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var sb strings.Builder
	for i, k := range keys {
		if i > 0 {
			sb.WriteString("&")
		}
		sb.WriteString(k)
		sb.WriteString("=")
		sb.WriteString(params[k])
	}
	sb.WriteString(s.apiSecret)

	hasher := sha1.New()
	hasher.Write([]byte(sb.String()))
	return hex.EncodeToString(hasher.Sum(nil))
}

func (s *CloudinaryStorageService) Upload(ctx context.Context, file io.Reader, filename string, mimeType string) (string, error) {
	uploadURL := fmt.Sprintf("https://api.cloudinary.com/v1_1/%s/image/upload", s.cloudName)

	timestamp := strconv.FormatInt(time.Now().Unix(), 10)
	paramsToSign := map[string]string{
		"folder":    s.folder,
		"timestamp": timestamp,
	}
	signature := s.generateSignature(paramsToSign)

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	_ = writer.WriteField("api_key", s.apiKey)
	_ = writer.WriteField("timestamp", timestamp)
	_ = writer.WriteField("folder", s.folder)
	_ = writer.WriteField("signature", signature)

	part, err := writer.CreateFormFile("file", filename)
	if err != nil {
		return "", fmt.Errorf("erro ao preparar multipart form file: %w", err)
	}

	if _, err := io.Copy(part, file); err != nil {
		return "", fmt.Errorf("erro ao copiar arquivo para multipart: %w", err)
	}

	if err := writer.Close(); err != nil {
		return "", fmt.Errorf("erro ao fechar multipart writer: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, uploadURL, body)
	if err != nil {
		return "", fmt.Errorf("erro ao instanciar requisição Cloudinary: %w", err)
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := s.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("falha ao enviar imagem para Cloudinary: %w", err)
	}
	defer resp.Body.Close()

	var clResp cloudinaryUploadResponse
	if err := json.NewDecoder(resp.Body).Decode(&clResp); err != nil {
		return "", fmt.Errorf("falha ao decodificar resposta do Cloudinary: %w", err)
	}

	if clResp.Error != nil && clResp.Error.Message != "" {
		return "", fmt.Errorf("erro retornado pelo Cloudinary: %s", clResp.Error.Message)
	}

	if clResp.SecureURL == "" {
		return "", fmt.Errorf("Cloudinary não retornou URL segura (status: %d)", resp.StatusCode)
	}

	secureURL := clResp.SecureURL
	if strings.Contains(secureURL, "/upload/") && !strings.Contains(secureURL, "/f_auto,q_auto") {
		secureURL = strings.Replace(secureURL, "/upload/", "/upload/f_auto,q_auto:good/", 1)
	}

	return secureURL, nil
}

// extractCloudinaryPublicID extrai o public_id correto da imagem a partir da URL ou identificador
func extractCloudinaryPublicID(identifier, folder string) string {
	// Remove query parameters ou hash se existirem
	identifier = strings.Split(identifier, "?")[0]
	identifier = strings.Split(identifier, "#")[0]

	if strings.Contains(identifier, "/upload/") {
		parts := strings.Split(identifier, "/upload/")
		if len(parts) > 1 {
			afterUpload := parts[1]
			segments := strings.Split(afterUpload, "/")
			var cleanSegments []string
			for _, seg := range segments {
				if seg == "" {
					continue
				}
				// Pula transformações (ex: "f_auto,q_auto:good", "w_500,h_500")
				if strings.Contains(seg, ",") || (strings.Contains(seg, "_") && (strings.HasPrefix(seg, "f_") || strings.HasPrefix(seg, "q_") || strings.HasPrefix(seg, "c_") || strings.HasPrefix(seg, "w_") || strings.HasPrefix(seg, "h_"))) {
					continue
				}
				// Pula segmento de versão numérica do Cloudinary (ex: "v1727061313")
				if strings.HasPrefix(seg, "v") && len(seg) > 1 {
					isVersion := true
					for _, c := range seg[1:] {
						if c < '0' || c > '9' {
							isVersion = false
							break
						}
					}
					if isVersion {
						continue
					}
				}
				cleanSegments = append(cleanSegments, seg)
			}
			if len(cleanSegments) > 0 {
				joined := strings.Join(cleanSegments, "/")
				ext := filepath.Ext(joined)
				if ext != "" {
					joined = strings.TrimSuffix(joined, ext)
				}
				return joined
			}
		}
	}

	cleaned := identifier
	ext := filepath.Ext(cleaned)
	if ext != "" {
		cleaned = strings.TrimSuffix(cleaned, ext)
	}

	if folder != "" && !strings.HasPrefix(cleaned, folder+"/") {
		return folder + "/" + cleaned
	}

	return cleaned
}

func (s *CloudinaryStorageService) Delete(ctx context.Context, identifier string) error {
	publicID := extractCloudinaryPublicID(identifier, s.folder)
	if publicID == "" {
		return fmt.Errorf("identificador de mídia inválido para exclusão: %s", identifier)
	}

	destroyURL := fmt.Sprintf("https://api.cloudinary.com/v1_1/%s/image/destroy", s.cloudName)
	timestamp := strconv.FormatInt(time.Now().Unix(), 10)

	// No Cloudinary, TODOS os parâmetros enviados (exceto api_key e signature) DEVEM estar na assinatura
	paramsToSign := map[string]string{
		"invalidate": "true",
		"public_id":  publicID,
		"timestamp":  timestamp,
	}
	signature := s.generateSignature(paramsToSign)

	form := url.Values{}
	form.Set("public_id", publicID)
	form.Set("timestamp", timestamp)
	form.Set("api_key", s.apiKey)
	form.Set("signature", signature)
	form.Set("invalidate", "true")

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, destroyURL, strings.NewReader(form.Encode()))
	if err != nil {
		return fmt.Errorf("erro ao preparar requisição de exclusão no Cloudinary: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("falha ao enviar requisição de exclusão para o Cloudinary: %w", err)
	}
	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("falha ao ler corpo da resposta de exclusão do Cloudinary: %w", err)
	}

	log.Printf("[Cloudinary] Exclusão de %s (status %d): %s", publicID, resp.StatusCode, string(bodyBytes))

	var clResp struct {
		Result string `json:"result"`
		Error  *struct {
			Message string `json:"message"`
		} `json:"error,omitempty"`
	}

	if err := json.Unmarshal(bodyBytes, &clResp); err != nil {
		return fmt.Errorf("falha ao decodificar resposta de exclusão do Cloudinary: %w (corpo: %s)", err, string(bodyBytes))
	}

	if clResp.Error != nil && clResp.Error.Message != "" {
		return fmt.Errorf("erro retornado pelo Cloudinary na exclusão: %s", clResp.Error.Message)
	}

	if clResp.Result != "ok" && clResp.Result != "not found" {
		return fmt.Errorf("resultado inesperado na exclusão do Cloudinary: %s", clResp.Result)
	}

	return nil
}

// NewStorageService instancia o provedor configurado ou realiza fallback automático para LocalStorageService
func NewStorageService(cfg *config.Config) StorageService {
	if cfg.CloudinaryCloudName != "" && cfg.CloudinaryAPIKey != "" && cfg.CloudinaryAPISecret != "" {
		return NewCloudinaryStorageService(
			cfg.CloudinaryCloudName,
			cfg.CloudinaryAPIKey,
			cfg.CloudinaryAPISecret,
			cfg.CloudinaryFolder,
		)
	}

	return NewLocalStorageService(cfg.UploadsDir, cfg.PublicBaseURL)
}

