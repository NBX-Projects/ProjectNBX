package config

import (
	"os"
	"testing"
)

func TestConfig_LoadConfig(t *testing.T) {
	// Defaults
	cfg := LoadConfig()
	if cfg == nil {
		t.Fatal("Expected non-nil Config")
	}
	if cfg.Port == "" {
		t.Error("Expected Port to have default value")
	}
	if cfg.JWTSecret == "" {
		t.Error("Expected JWTSecret to have default value")
	}

	// Environment overrides
	os.Setenv("PORT", "9999")
	os.Setenv("JWT_SECRET", "custom_secret_test")
	defer func() {
		os.Unsetenv("PORT")
		os.Unsetenv("JWT_SECRET")
	}()

	customCfg := LoadConfig()
	if customCfg.Port != "9999" {
		t.Errorf("Expected Port 9999, got %s", customCfg.Port)
	}
	if customCfg.JWTSecret != "custom_secret_test" {
		t.Errorf("Expected JWTSecret custom_secret_test, got %s", customCfg.JWTSecret)
	}
}

func TestConfig_GetEnvFallback(t *testing.T) {
	val := getEnv("NON_EXISTENT_VAR_XYZ_123", "fallback_val")
	if val != "fallback_val" {
		t.Errorf("Expected fallback_val, got %s", val)
	}

	os.Setenv("TEST_VAR_EXISTENT", "actual_val")
	defer os.Unsetenv("TEST_VAR_EXISTENT")
	val2 := getEnv("TEST_VAR_EXISTENT", "fallback_val")
	if val2 != "actual_val" {
		t.Errorf("Expected actual_val, got %s", val2)
	}
}
