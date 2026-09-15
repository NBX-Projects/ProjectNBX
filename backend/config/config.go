package config

import (
	"bufio"
	"os"
	"strings"
)

// Config armazena as configurações da aplicação
type Config struct {
	Port           string
	JWTSecret      string
	LiveKitURL     string
	LiveKitAPIKey  string
	LiveKitSecret  string
	AllowedOrigins string
	DatabaseURL    string
	MigrationsDir  string
}

// LoadConfig carrega as configurações das variáveis de ambiente com valores padrão
func LoadConfig() *Config {
	loadDotEnv()

	return &Config{
		Port:           getEnv("PORT", "8080"),
		JWTSecret:      getEnv("JWT_SECRET", "super_secret_jwt_key_projectnbx_change_me_in_production"),
		LiveKitURL:     getEnv("LIVEKIT_URL", "ws://localhost:7880"),
		LiveKitAPIKey:  getEnv("LIVEKIT_API_KEY", "devkey"),
		LiveKitSecret:  getEnv("LIVEKIT_API_SECRET", "secret"),
		AllowedOrigins: getEnv("ALLOWED_ORIGINS", "*"),
		DatabaseURL:    getEnv("DATABASE_URL", "postgres://admin@localhost:8190/nbx_stream?sslmode=disable"),
		MigrationsDir:  getEnv("MIGRATIONS_DIR", "migrations"),
	}
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
