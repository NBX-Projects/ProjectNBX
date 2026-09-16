package swagger

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestSwagger_HandlerJSON(t *testing.T) {
	req := httptest.NewRequest("GET", "/swagger/doc.json", nil)
	rr := httptest.NewRecorder()

	HandlerJSON(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("esperado status 200, obtido %d", rr.Code)
	}

	contentType := rr.Header().Get("Content-Type")
	if !strings.Contains(contentType, "application/json") {
		t.Errorf("esperado Content-Type contendo application/json, obtido %s", contentType)
	}

	// Valida se o conteúdo é um JSON válido
	var parsed map[string]interface{}
	if err := json.Unmarshal(rr.Body.Bytes(), &parsed); err != nil {
		t.Fatalf("OpenAPISpecJSON não é um JSON válido: %v", err)
	}

	if parsed["openapi"] != "3.0.3" {
		t.Errorf("esperado openapi versão 3.0.3, obtido %v", parsed["openapi"])
	}

	info, ok := parsed["info"].(map[string]interface{})
	if !ok || info["title"] != "ProjectNBX Backend API" {
		t.Errorf("título da API incorreto: %v", info)
	}
}

func TestSwagger_HandlerUI(t *testing.T) {
	req := httptest.NewRequest("GET", "/swagger/", nil)
	rr := httptest.NewRecorder()

	HandlerUI(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("esperado status 200, obtido %d", rr.Code)
	}

	contentType := rr.Header().Get("Content-Type")
	if !strings.Contains(contentType, "text/html") {
		t.Errorf("esperado Content-Type text/html, obtido %s", contentType)
	}

	body := rr.Body.String()
	if !strings.Contains(body, "SwaggerUIBundle") {
		t.Errorf("esperado corpo HTML contendo SwaggerUIBundle")
	}

	if !strings.Contains(body, "ProjectNBX API") {
		t.Errorf("esperado corpo HTML contendo ProjectNBX API")
	}
}
