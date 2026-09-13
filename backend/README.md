# 🚀 ProjectNBX Backend (Go / Golang)

Serviço de backend de alta performance para o **ProjectNBX**, responsável por autenticação de usuários, gerenciamento de servidores/canais, broadcast em tempo real via **WebSockets** e geração de tokens de acesso **LiveKit SFU (WebRTC)** para voz e compartilhamento de tela com ultrabaixa latência.

---

## 🏛️ Arquitetura e Tecnologias

* **Linguagem:** Go 1.22+
* **Roteamento & Middlewares:** Gorilla Mux (CORS, Auth JWT, Logging, Panic Recovery)
* **Tempo Real:** Gorilla WebSocket Hub (mensagens de chat, presença de usuários e estados de voz)
* **SFU WebRTC:** LiveKit Protocol SDK (`github.com/livekit/protocol/auth`)
* **Autenticação:** JSON Web Tokens (JWT) com criptografia de senhas via `bcrypt`
* **Orquestração:** Docker Compose (LiveKit Server + Redis + Go Backend)

---

## 📁 Estrutura de Diretórios

```
backend/
├── cmd/
│   └── api/
│       └── main.go              # Ponto de entrada do backend
├── config/
│   └── config.go                # Leitura de variáveis de ambiente
├── internal/
│   ├── auth/
│   │   ├── jwt.go               # Geração/Validação de JWT
│   │   └── livekit.go           # Concessão de VideoGrants do LiveKit
│   ├── handlers/
│   │   ├── auth_handler.go      # Rotas de Login, Registro e Me
│   │   ├── livekit_handler.go   # Rota de geração de tokens LiveKit
│   │   ├── server_handler.go    # CRUD de Servidores, Canais e Mensagens
│   │   └── ws_handler.go        # Upgrade e ciclo de vida do WebSocket
│   ├── models/
│   │   ├── user.go              # Modelos de Usuário e Auth
│   │   ├── server.go            # Modelos de Servidor e Canais
│   │   ├── message.go           # Modelos de Mensagens
│   │   └── ws_events.go         # Definições de eventos de WebSocket
│   ├── repository/
│   │   ├── repository.go        # Interface de persistência
│   │   └── memory_repo.go       # Implementação thread-safe em memória
│   ├── router/
│   │   └── router.go            # Configuração das rotas HTTP e Middlewares
│   └── websocket/
│       ├── hub.go               # Hub de broadcast e gerenciamento de salas
│       └── client.go            # Leitura/escrita e heartbeat (ping/pong)
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── livekit.yaml
└── go.mod
```

---

## ⚡ Como Executar

### Opção 1: Via Docker Compose (Recomendado - Sobe Backend + LiveKit + Redis)

```bash
cd backend
docker-compose up -d --build
```

O backend estará acessível em `http://localhost:8080` e o LiveKit SFU em `ws://localhost:7880`.

### Opção 2: Execução Nativa em Go

```bash
cd backend
go mod tidy
go run cmd/api/main.go
```

---

## 📡 Documentação de Endpoints (REST API)

### 🩺 Health Check
* `GET /api/health` — Verifica o status do backend e configuração do LiveKit.

---

### 🔑 Autenticação

#### 1. Registrar Usuário
* `POST /api/auth/register`
* **Body:**
  ```json
  {
    "username": "meu_usuario",
    "email": "dev@nbx.com",
    "password": "senha_segura_123"
  }
  ```

#### 2. Login
* `POST /api/auth/login`
* **Body:**
  ```json
  {
    "email": "dev@nbx.com",
    "password": "senha_segura_123"
  }
  ```
* **Retorno:**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "usr_dev_1",
      "username": "meu_usuario",
      "email": "dev@nbx.com",
      "status": "online"
    }
  }
  ```

#### 3. Usuário Atual
* `GET /api/auth/me` *(Requer Header `Authorization: Bearer <token>`)*

---

### 🎙️ Voz WebRTC (LiveKit Token)

#### Gerar Token para Entrar em Sala de Voz
* `POST /api/voice/token` *(Requer Header `Authorization: Bearer <token>`)*
* **Body:**
  ```json
  {
    "room_name": "chn_voice_lounge",
    "participant_name": "meu_usuario"
  }
  ```
* **Retorno:**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "server_url": "ws://localhost:7880",
    "room_name": "chn_voice_lounge"
  }
  ```
*(O token gerado pode ser passado diretamente para o `LiveKitClient.connect()` no Flutter)*.

---

### 🏰 Servidores & Canais *(Rotas Protegidas por JWT)*

* `GET /api/servers` — Lista os servidores disponíveis
* `POST /api/servers` — Cria um novo servidor
* `GET /api/servers/{id}` — Detalhes de um servidor
* `GET /api/servers/{id}/channels` — Lista canais do servidor
* `POST /api/servers/{id}/channels` — Cria um canal (`type`: `"text"` ou `"voice"`)
* `GET /api/servers/{id}/channels/{channelId}/messages` — Histórico de mensagens
* `POST /api/servers/{id}/channels/{channelId}/messages` — Envia mensagem no canal

---

## 💬 WebSocket em Tempo Real (`/ws`)

Conexão: `ws://localhost:8080/ws?token=<JWT_TOKEN>&server_id=<SERVER_ID>`

### Enviar Mensagem de Chat:
```json
{
  "type": "CHAT_MESSAGE",
  "channel_id": "chn_general_chat",
  "server_id": "srv_main_nbx",
  "payload": {
    "content": "Olá a todos no ProjectNBX!"
  }
}
```

### Atualizar Estado de Voz (Speaking / Mute):
```json
{
  "type": "VOICE_STATE",
  "channel_id": "chn_voice_lounge",
  "payload": {
    "user_id": "usr_dev_1",
    "channel_id": "chn_voice_lounge",
    "is_speaking": true,
    "is_muted": false,
    "is_deafened": false
  }
}
```
