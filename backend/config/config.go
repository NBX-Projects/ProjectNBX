package config

import (
	"os"
)

// Config armazena as configurações da aplicação
type Config struct {
	Port            string
	JWTSecret       string
	LiveKitURL      string
	LiveKitAPIKey   string
	LiveKitSecret   string
	AllowedOrigins  string
}

// LoadConfig carrega as configurações das variáveis de ambiente com valores padrão
func LoadConfig() *Config {
	return &Config{
		Port:           getEnv("PORT", "8080"),
		JWTSecret:      getEnv("JWT_SECRET", "projectnbx-super-secret-jwt-key-change-in-production"),
		LiveKitURL:     getEnv("LIVEKIT_URL", "ws://localhost:7880"),
		LiveKitAPIKey:  getEnv("LIVEKIT_API_KEY", "devkey"),
		LiveKitSecret:  getEnv("LIVEKIT_API_SECRET", "secret"),
		AllowedOrigins: getEnv("ALLOWED_ORIGINS", "*"),
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists && value != "" {
		return value
	}
	return fallback
}
