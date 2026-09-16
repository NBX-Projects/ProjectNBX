// Package swagger fornece documentação interativa OpenAPI 3.0 e Swagger UI para o backend do ProjectNBX.
package swagger

import (
	"net/http"
)

// HandlerJSON serve a especificação OpenAPI 3.0 em formato JSON
func HandlerJSON(w http.ResponseWriter, req *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	_, _ = w.Write([]byte(OpenAPISpecJSON))
}

// HandlerUI serve a interface interativa do Swagger UI
func HandlerUI(w http.ResponseWriter, req *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_, _ = w.Write([]byte(swaggerUIHTML))
}

const swaggerUIHTML = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>ProjectNBX API — Swagger Documentation</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui.min.css" />
  <link rel="icon" type="image/png" href="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/favicon-32x32.png" />
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Space+Grotesk:wght@600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
      background: #181926;
      color: #cad3f5;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    .nbx-banner {
      background: #1e2030;
      border-bottom: 1px solid #313244;
      padding: 14px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
    }
    .nbx-banner .logo-area {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .nbx-banner .badge-title {
      font-family: 'Space Grotesk', sans-serif;
      font-size: 1.25rem;
      font-weight: 700;
      color: #f5cba7;
      letter-spacing: -0.5px;
    }
    .nbx-banner .badge-ver {
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.75rem;
      background: #313244;
      color: #a8c5b5;
      padding: 3px 8px;
      border-radius: 9999px;
      font-weight: 600;
    }
    .nbx-links {
      display: flex;
      gap: 10px;
      align-items: center;
    }
    .nbx-btn {
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      font-weight: 600;
      text-decoration: none;
      padding: 6px 14px;
      border-radius: 9999px;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s ease;
    }
    .nbx-btn-health {
      background: rgba(168, 197, 181, 0.15);
      border: 1px solid #a8c5b5;
      color: #a8c5b5;
    }
    .nbx-btn-health:hover {
      background: #a8c5b5;
      color: #181926;
    }
    .nbx-btn-json {
      background: #313244;
      border: 1px solid #45475a;
      color: #c5b4e3;
    }
    .nbx-btn-json:hover {
      background: #c5b4e3;
      color: #181926;
    }
    /* Customização do Swagger UI Dark Theme */
    .swagger-ui {
      max-width: 1300px;
      margin: 0 auto;
      padding: 20px;
      filter: invert(88%) hue-rotate(180deg);
    }
    .swagger-ui .topbar { display: none; }
    .swagger-ui img { filter: invert(100%) hue-rotate(180deg); }
  </style>
</head>
<body>
  <header class="nbx-banner">
    <div class="logo-area">
      <span style="font-size: 1.4rem;">⚡</span>
      <span class="badge-title">ProjectNBX API</span>
      <span class="badge-ver">v1.0.0</span>
      <span style="font-size: 0.85rem; color: #a5adcb;">Go 1.22+ • Postgres 16 • LiveKit SFU</span>
    </div>
    <div class="nbx-links">
      <a href="/api/health" target="_blank" class="nbx-btn nbx-btn-health">🩺 Health Check</a>
      <a href="/swagger/doc.json" target="_blank" class="nbx-btn nbx-btn-json">📄 OpenAPI JSON</a>
    </div>
  </header>

  <div id="swagger-ui"></div>

  <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui-bundle.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui-standalone-preset.min.js"></script>
  <script>
    window.onload = function() {
      window.ui = SwaggerUIBundle({
        url: "/swagger/doc.json",
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout",
        docExpansion: "list",
        persistAuthorization: true
      });
    };
  </script>
</body>
</html>`

// OpenAPISpecJSON especificação OpenAPI 3.0 da API do ProjectNBX
const OpenAPISpecJSON = `{
  "openapi": "3.0.3",
  "info": {
    "title": "ProjectNBX Backend API",
    "version": "1.0.0",
    "description": "API REST, WebSocket e WebRTC (LiveKit SFU) do ecossistema ProjectNBX — Plataforma de comunicação e colaboração moderna para desenvolvedores e gamers.",
    "contact": {
      "name": "ProjectNBX Engineering",
      "url": "https://github.com/projectnbx"
    }
  },
  "servers": [
    {
      "url": "/",
      "description": "Servidor Atual (Host Local ou Produção)"
    }
  ],
  "tags": [
    { "name": "Health", "description": "Status, diagnóstico e monitoramento do ambiente" },
    { "name": "Auth", "description": "Autenticação, cadastro e sessão de usuários" },
    { "name": "Voice", "description": "WebRTC SFU via LiveKit (salas de voz e tokens)" },
    { "name": "Servers", "description": "Gestão de servidores / workspaces" },
    { "name": "Channels", "description": "Canais de texto e de voz" },
    { "name": "Messages", "description": "Mensagens de chat em tempo real" },
    { "name": "Members & Invites", "description": "Membros e links temporários de convite" },
    { "name": "Users", "description": "Busca e perfis de usuários" },
    { "name": "Audit", "description": "Logs de auditoria e segurança" },
    { "name": "Realtime", "description": "Conexões WebSocket e Webhooks SFU" }
  ],
  "paths": {
    "/api/health": {
      "get": {
        "tags": ["Health"],
        "summary": "Health Check do Ambiente",
        "description": "Verifica se o backend Go, o banco de dados PostgreSQL e o LiveKit SFU estão online e responsivos.",
        "responses": {
          "200": {
            "description": "Ambiente saudável e operacional",
            "content": {
              "application/json": {
                "example": {
                  "status": "healthy",
                  "app": "ProjectNBX Backend",
                  "version": "1.0.0",
                  "timestamp": "2026-09-15T23:50:00Z",
                  "uptime": "15m42s",
                  "components": {
                    "database": { "status": "up", "latency_ms": 0.8 },
                    "livekit": { "status": "configured", "url": "ws://localhost:7880" },
                    "websocket": { "status": "active" }
                  }
                }
              }
            }
          },
          "503": {
            "description": "Serviço degradado ou falha de banco de dados"
          }
        }
      }
    },
    "/health": {
      "get": {
        "tags": ["Health"],
        "summary": "Alias público para Health Check",
        "description": "Alias direto para monitoramento por balanceadores e testes de conectividade.",
        "responses": {
          "200": { "description": "Ambiente saudável" }
        }
      }
    },
    "/api/auth/register": {
      "post": {
        "tags": ["Auth"],
        "summary": "Cadastrar novo usuário",
        "description": "Cria uma conta de usuário com senha criptografada em Bcrypt.",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["username", "email", "password"],
                "properties": {
                  "username": { "type": "string", "example": "john_doe" },
                  "email": { "type": "string", "format": "email", "example": "dev@projectnbx.com" },
                  "password": { "type": "string", "format": "password", "example": "SenhaForte123*" }
                }
              }
            }
          }
        },
        "responses": {
          "201": { "description": "Usuário criado com sucesso" },
          "400": { "description": "Dados inválidos" },
          "409": { "description": "E-mail ou nome de usuário já em uso" }
        }
      }
    },
    "/api/auth/login": {
      "post": {
        "tags": ["Auth"],
        "summary": "Autenticar usuário",
        "description": "Valida as credenciais e emite um token JWT de 72 horas.",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["email", "password"],
                "properties": {
                  "email": { "type": "string", "format": "email", "example": "dev@projectnbx.com" },
                  "password": { "type": "string", "format": "password", "example": "SenhaForte123*" }
                }
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Login realizado com sucesso",
            "content": {
              "application/json": {
                "example": {
                  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                  "user": {
                    "id": "usr_dev_1",
                    "username": "john_doe",
                    "email": "dev@projectnbx.com",
                    "status": "online"
                  }
                }
              }
            }
          },
          "401": { "description": "Credenciais inválidas" }
        }
      }
    },
    "/api/auth/me": {
      "get": {
        "tags": ["Auth"],
        "summary": "Obter perfil do usuário autenticado",
        "security": [{ "BearerAuth": [] }],
        "responses": {
          "200": { "description": "Dados do usuário autenticado" },
          "401": { "description": "Token ausente ou inválido" }
        }
      }
    },
    "/api/voice/token": {
      "post": {
        "tags": ["Voice"],
        "summary": "Gerar token de áudio/WebRTC LiveKit",
        "description": "Gera token assinado com VideoGrants para conexão ao SFU de baixa latência.",
        "security": [{ "BearerAuth": [] }],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["room"],
                "properties": {
                  "room": { "type": "string", "example": "chn_voice_general" },
                  "identity": { "type": "string", "example": "usr_dev_1" },
                  "name": { "type": "string", "example": "john_doe" }
                }
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Token LiveKit gerado",
            "content": {
              "application/json": {
                "example": {
                  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                  "url": "ws://localhost:7880",
                  "room": "chn_voice_general"
                }
              }
            }
          },
          "401": { "description": "Não autorizado" }
        }
      }
    },
    "/api/servers": {
      "get": {
        "tags": ["Servers"],
        "summary": "Listar servidores acessíveis",
        "security": [{ "BearerAuth": [] }],
        "responses": {
          "200": { "description": "Lista de servidores" },
          "401": { "description": "Não autorizado" }
        }
      },
      "post": {
        "tags": ["Servers"],
        "summary": "Criar novo servidor",
        "security": [{ "BearerAuth": [] }],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["name"],
                "properties": {
                  "name": { "type": "string", "example": "Developers Lounge" },
                  "icon": { "type": "string", "example": "https://example.com/icon.png" }
                }
              }
            }
          }
        },
        "responses": {
          "201": { "description": "Servidor criado" },
          "401": { "description": "Não autorizado" }
        }
      }
    },
    "/api/servers/{id}": {
      "get": {
        "tags": ["Servers"],
        "summary": "Obter detalhes de um servidor",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }
        ],
        "responses": {
          "200": { "description": "Detalhes do servidor" },
          "404": { "description": "Servidor não encontrado" }
        }
      }
    },
    "/api/servers/{id}/channels": {
      "get": {
        "tags": ["Channels"],
        "summary": "Listar canais do servidor",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }
        ],
        "responses": {
          "200": { "description": "Lista de canais de texto e voz" }
        }
      },
      "post": {
        "tags": ["Channels"],
        "summary": "Criar canal no servidor",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["name", "type"],
                "properties": {
                  "name": { "type": "string", "example": "geral" },
                  "type": { "type": "string", "enum": ["TEXT", "VOICE"], "example": "TEXT" }
                }
              }
            }
          }
        },
        "responses": {
          "201": { "description": "Canal criado" }
        }
      }
    },
    "/api/servers/{id}/channels/{channelId}/messages": {
      "get": {
        "tags": ["Messages"],
        "summary": "Histórico de mensagens do canal",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "string" } },
          { "name": "channelId", "in": "path", "required": true, "schema": { "type": "string" } },
          { "name": "limit", "in": "query", "schema": { "type": "integer", "default": 50 } }
        ],
        "responses": {
          "200": { "description": "Lista de mensagens ordenadas cronologicamente" }
        }
      }
    },
    "/api/servers/{id}/invites": {
      "get": {
        "tags": ["Members & Invites"],
        "summary": "Listar convites ativos do servidor",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }
        ],
        "responses": { "200": { "description": "Lista de convites" } }
      },
      "post": {
        "tags": ["Members & Invites"],
        "summary": "Criar link de convite temporário",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "string" } }
        ],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "max_uses": { "type": "integer", "example": 25 },
                  "expires_in_hours": { "type": "integer", "example": 48 }
                }
              }
            }
          }
        },
        "responses": { "201": { "description": "Convite criado" } }
      }
    },
    "/api/servers/join/{code}": {
      "post": {
        "tags": ["Members & Invites"],
        "summary": "Entrar em servidor usando código de convite",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "code", "in": "path", "required": true, "schema": { "type": "string", "example": "aB3k9X" } }
        ],
        "responses": {
          "200": { "description": "Entrou no servidor com sucesso" },
          "400": { "description": "Convite inválido, expirado ou com limite atingido" }
        }
      }
    },
    "/api/users/search": {
      "get": {
        "tags": ["Users"],
        "summary": "Buscar usuários por nome ou email",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "q", "in": "query", "required": true, "schema": { "type": "string" } }
        ],
        "responses": { "200": { "description": "Lista de usuários correspondentes" } }
      }
    },
    "/api/audit-logs": {
      "get": {
        "tags": ["Audit"],
        "summary": "Listar logs de auditoria do sistema",
        "security": [{ "BearerAuth": [] }],
        "parameters": [
          { "name": "source", "in": "query", "schema": { "type": "string", "enum": ["AUTH", "SERVER", "CHANNEL", "CHAT", "VOICE", "USER", "SYSTEM", "ADMIN"] } }
        ],
        "responses": { "200": { "description": "Logs de auditoria recentes" } }
      }
    },
    "/ws": {
      "get": {
        "tags": ["Realtime"],
        "summary": "Conexão WebSocket em tempo real",
        "description": "Estabelece conexão bidirecional persistente para mensagens de chat, eventos de presença e sinalização de voz.",
        "parameters": [
          { "name": "token", "in": "query", "required": true, "schema": { "type": "string" }, "description": "Token JWT de autenticação" },
          { "name": "server_id", "in": "query", "schema": { "type": "string" } },
          { "name": "channel_id", "in": "query", "schema": { "type": "string" } }
        ],
        "responses": {
          "101": { "description": "Switching Protocols to WebSocket" },
          "401": { "description": "Token ausente ou inválido" }
        }
      }
    }
  },
  "components": {
    "securitySchemes": {
      "BearerAuth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT",
        "description": "Insira o token JWT retornado na rota /api/auth/login"
      }
    }
  }
}`
