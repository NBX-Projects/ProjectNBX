package config

import (
	"bufio"
	"fmt"
	"net/url"
	"os"
	"strings"
)

// Config armazena as configurações da aplicação
type Config struct {
	Environment         string
	Port                string
	JWTSecret           string
	LiveKitURL          string
	LiveKitAPIURL       string
	LiveKitAPIKey       string
	LiveKitSecret       string
	AllowedOrigins      string
	DatabaseURL         string
	MigrationsDir       string
	CloudinaryCloudName string
	CloudinaryAPIKey    string
	CloudinaryAPISecret string
	CloudinaryFolder    string
	UploadsDir          string
	PublicBaseURL       string
	AuditAdminUserIDs   string
}

// LoadConfig carrega as configurações das variáveis de ambiente com valores padrão
func LoadConfig() *Config {
	loadDotEnv()

	cloudName := getEnv("CLOUDINARY_CLOUD_NAME", "")
	apiKey := getEnv("CLOUDINARY_API_KEY", "")
	apiSecret := getEnv("CLOUDINARY_API_SECRET", "")

	if clURL := os.Getenv("CLOUDINARY_URL"); clURL != "" {
		clean := strings.TrimPrefix(clURL, "cloudinary://")
		if atIdx := strings.LastIndex(clean, "@"); atIdx != -1 {
			if cloudName == "" {
				cloudName = clean[atIdx+1:]
			}
			creds := clean[:atIdx]
			parts := strings.SplitN(creds, ":", 2)
			if len(parts) == 2 {
				if apiKey == "" {
					apiKey = parts[0]
				}
				if apiSecret == "" {
					apiSecret = parts[1]
				}
			}
		}
	}

	return &Config{
		Environment:         getEnv("APP_ENV", "development"),
		Port:                getEnv("PORT", "8080"),
		JWTSecret:           getEnv("JWT_SECRET", "super_secret_jwt_key_projectnbx_change_me_in_production"),
		LiveKitURL:          getEnv("LIVEKIT_URL", "ws://localhost:7880"),
		LiveKitAPIURL:       getEnv("LIVEKIT_API_URL", "http://localhost:7880"),
		LiveKitAPIKey:       getEnv("LIVEKIT_API_KEY", "devkey"),
		LiveKitSecret:       getEnv("LIVEKIT_API_SECRET", "secret"),
		AllowedOrigins:      getEnv("ALLOWED_ORIGINS", "*"),
		DatabaseURL:         getEnv("DATABASE_URL", "postgres://admin@localhost:8190/nbx_stream?sslmode=disable"),
		MigrationsDir:       getEnv("MIGRATIONS_DIR", "migrations"),
		CloudinaryCloudName: cloudName,
		CloudinaryAPIKey:    apiKey,
		CloudinaryAPISecret: apiSecret,
		CloudinaryFolder:    getEnv("CLOUDINARY_FOLDER", "projectnbx"),
		UploadsDir:          getEnv("UPLOADS_DIR", "uploads"),
		PublicBaseURL:       getEnv("PUBLIC_BASE_URL", "http://localhost:8080"),
		AuditAdminUserIDs:   getEnv("AUDIT_ADMIN_USER_IDS", ""),
	}
}

// Validate checks fail-closed settings that are required in production.
func (c *Config) Validate() error {
	if !strings.EqualFold(c.Environment, "production") {
		return nil
	}

	if c.JWTSecret == "" || len(c.JWTSecret) < 32 || strings.Contains(strings.ToLower(c.JWTSecret), "change_me") {
		return fmt.Errorf("JWT_SECRET must be explicitly configured with at least 32 characters")
	}
	if c.LiveKitAPIKey == "" || c.LiveKitAPIKey == "devkey" || c.LiveKitSecret == "" || c.LiveKitSecret == "secret" {
		return fmt.Errorf("production LiveKit credentials must be explicitly configured")
	}
	liveKitURL, liveKitErr := url.Parse(c.LiveKitURL)
	if liveKitErr != nil || liveKitURL == nil || liveKitURL.Scheme != "wss" || liveKitURL.Host == "" {
		return fmt.Errorf("production LIVEKIT_URL must be a public WSS URL")
	}
	databaseURL, databaseErr := url.Parse(c.DatabaseURL)
	if databaseErr != nil || databaseURL == nil {
		return fmt.Errorf("production DATABASE_URL must use a remote database with TLS enabled")
	}
	databaseSSLMode := strings.ToLower(databaseURL.Query().Get("sslmode"))
	if (databaseURL.Scheme != "postgres" && databaseURL.Scheme != "postgresql") || databaseURL.Hostname() == "" || strings.EqualFold(databaseURL.Hostname(), "localhost") || databaseURL.Hostname() == "127.0.0.1" || (databaseSSLMode != "require" && databaseSSLMode != "verify-ca" && databaseSSLMode != "verify-full") {
		return fmt.Errorf("production DATABASE_URL must use a remote database with TLS enabled")
	}
	if strings.TrimSpace(c.AllowedOrigins) == "" || strings.TrimSpace(c.AllowedOrigins) == "*" {
		return fmt.Errorf("production ALLOWED_ORIGINS must contain explicit HTTPS origins")
	}
	for _, origin := range strings.Split(c.AllowedOrigins, ",") {
		parsed, err := url.Parse(strings.TrimSpace(origin))
		if err != nil || parsed.Scheme != "https" || parsed.Host == "" || parsed.Path != "" {
			return fmt.Errorf("each production ALLOWED_ORIGINS entry must be an HTTPS origin")
		}
	}
	if strings.TrimSpace(c.AuditAdminUserIDs) == "" {
		return fmt.Errorf("production AUDIT_ADMIN_USER_IDS must list authorized audit administrators")
	}
	return nil
}

func (c *Config) IsAuditAdmin(userID string) bool {
	if userID == "" {
		return false
	}
	for _, configuredID := range strings.Split(c.AuditAdminUserIDs, ",") {
		if strings.TrimSpace(configuredID) == userID {
			return true
		}
	}
	return false
}

// loadDotEnv carrega variáveis de um arquivo .env se existir
func loadDotEnv() {
	candidates := []string{".env", "backend/.env", "../.env", "../../.env"}
	for _, path := range candidates {
		file, err := os.Open(path)
		if err == nil {
			defer file.Close()
			scanner := bufio.NewScanner(file)
			for scanner.Scan() {
				line := strings.TrimSpace(scanner.Text())
				if line == "" || strings.HasPrefix(line, "#") {
					continue
				}
				parts := strings.SplitN(line, "=", 2)
				if len(parts) == 2 {
					key := strings.TrimSpace(parts[0])
					val := strings.TrimSpace(parts[1])
					val = strings.Trim(val, `"'`)
					if _, exists := os.LookupEnv(key); !exists {
						_ = os.Setenv(key, val)
					}
				}
			}
			if err := scanner.Err(); err != nil {
				// Ignora erro de leitura não fatal em .env
				_ = err
			}
			break
		}
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists && value != "" {
		return value
	}
	return fallback
}
