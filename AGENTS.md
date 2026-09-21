# 🤖 AGENTS.md — Diretrizes de Desenvolvimento, Arquitetura e Automação

Este documento define os padrões de arquitetura, convenções de código, diretrizes de design e regras de automação para Agentes de IA e desenvolvedores que trabalham no ecossistema do **ProjectNBX**.

---

## 🎯 1. Visão do Projeto e Escopo

O **ProjectNBX** é uma plataforma de comunicação e colaboração moderna e de alta performance voltada para desenvolvedores e gamers.
* **Metas de Performance:** Baixo consumo de memória (< 80 MB em Desktop), áudio de latência ultrabaixa (< 50 ms com LiveKit SFU) e responsividade fluida.
* **Plataformas Alvo:** Windows, macOS, Linux, Android, iOS e Web a partir de uma base de código Flutter unificada.
* **Backend:** Microserviço em Go 1.22+ integrado a **PostgreSQL 16** real, **Redis 7** e **LiveKit Server**.

---

## 🏛️ 2. Arquitetura e Estrutura de Diretórios

### 📱 Frontend Flutter (`lib/` - *Feature-First Architecture*)

```
lib/
├── core/                       # Utilitários compartilhados, temas, constantes e rede
│   ├── network/                # ApiClient HTTP e WebSocketClient
│   ├── theme/                  # Design System (AppColors, AppTheme, ThemeController)
│   └── utils/                  # Formatadores e helpers gerais
├── features/                   # Módulos isolados por funcionalidade
│   ├── auth/                   # Autenticação, login/registro, sessão e UserModel
│   │   ├── controllers/        # Gerenciamento de estado (Riverpod StateNotifier)
│   │   ├── models/             # Entidades e DTOs de autenticação
│   │   └── screens/            # Telas de login e onboarding
│   ├── chat/                   # Canais de texto e mensagens em tempo real
│   ├── servers/                # Lista de servidores, categorias e canais
│   ├── voice/                  # WebRTC, LiveKit rooms, PTT e áudio
│   │   ├── controllers/        # Gerenciamento de estado da sala de voz
│   │   ├── services/           # Integração com LiveKit e WebRTC
│   │   └── widgets/            # UI dos canais de voz e grids de participantes
│   └── settings/               # Configurações de áudio, microfone, atalhos e tema
└── main.dart                   # Inicialização, window_manager e ProviderScope
```

### 🐹 Backend em Go (`backend/`)

```
backend/
├── cmd/
│   └── api/
│       └── main.go             # Ponto de entrada, conexão Postgres e boot de migrations
├── config/
│   └── config.go               # Leitura de variáveis de ambiente e banco
├── internal/
│   ├── auth/                   # JWT Service e LiveKit VideoGrants
│   ├── database/               # Conexão Postgres (db.go) e Migrator SQL (migrator.go)
│   ├── handlers/               # HTTP Handlers (auth, servers, voice, ws, audit)
│   ├── models/                 # Modelos Go (user, server, channel, message, audit)
│   ├── repository/             # Interface Repository e PostgresRepository
│   ├── router/                 # Rotas Gorilla Mux e middlewares (CORS, JWT, logging)
│   └── websocket/              # WebSocket Hub em tempo real (chat, voz e presença)
├── migrations/                 # Scripts SQL versionados (000001_..., 000002_...)
├── Dockerfile                  # Multi-stage build leve em Alpine
└── docker-compose.yml          # Postgres 16 + Redis 7 + LiveKit SFU + Backend
```

---

## 🎨 3. Padrões de Interface e Design System

O projeto adota uma identidade visual única e moderna inspirada em estética de terminal/desenvolvedor e materiais táteis (Pastel Tech + Forest Slate), evitando designs genéricos:

### 🌘 Modo Escuro (*Pastel Tech Aesthetic*)
- **Canvas Base:** `#181926` (*Deep Matte Charcoal*)
- **Painéis e Cards:** `#1E2030` com bordas estruturais de 1px em `#313244`
- **Campos Inset:** `#141520`
- **Destaque Primário:** `#F5CBA7` (*Warm Pastel Peach*) em botões *Pill* (`border-radius: 9999px`) com texto escuro
- **Acentos Funcionais:** `#A8C5B5` (*Pastel Sage* para status/voz ativa), `#C5B4E3` (*Soft Lavender*), `#A5C4D4` (*Powder Blue*)
- **Tipografia:** `Space Grotesk` (títulos) + `JetBrains Mono` (botões, código e chips) + `Inter` (corpo)

### ☀️ Modo Claro (*Forest Slate Aesthetic*)
- **Canvas Base:** `#FAF9F6` (*Alabaster Cream*) 100% limpo e sem artefatos/manchas
- **Painéis e Cards:** `#FFFFFF` (*Pure White*) com bordas sutis em `#E2E8F0`
- **Destaque Primário:** `#2D6A4F` (*Forest Sage*) em botões *Pill* com texto branco
- **Acentos Funcionais:** `#2C5E8A` (*Deep Slate Blue*), `#5B4282` (*Royal Lavender*), `#A05022` (*Terracotta*)
- **Tipografia:** `Plus Jakarta Sans` (títulos) + `JetBrains Mono` + `Inter`

### 🔄 Transição de Tema
- Utilizar sempre `AnimatedTheme` e `AnimatedContainer` com duração de **300ms** (`Curves.easeInOut`) para garantir transições suaves entre temas claro e escuro.
- Gerenciamento de tema reativo via `themeModeProvider`.

---

## 🗄️ 4. Banco de Dados, Migrations e Auditoria

1. **PostgreSQL Real:**
   - Nada de mocks em produção ou testes de backend: utilizar sempre o **PostgreSQL 16** via Docker Compose com volume persistente `postgres_data`.
2. **Migrations SQL Versionadas:**
   - Todas as alterações de schema devem ser criadas na pasta `backend/migrations/` no padrão `XXXXXX_nome.up.sql` e `XXXXXX_nome.down.sql`.
   - O `migrator.go` aplica automaticamente migrações pendentes em ordem transacional na inicialização do backend.
3. **Tabela e Sistema de Auditoria (`audit_logs`):**
   - Utilizar o tipo ENUM PostgreSQL `audit_source`: `'AUTH'`, `'SERVER'`, `'CHANNEL'`, `'CHAT'`, `'VOICE'`, `'USER'`, `'SYSTEM'`, `'ADMIN'`.
   - Registrar ações críticas (ex: logins, cadastros, criação de servidores, alterações de permissão) com IP, User-Agent e metadados JSONB.

---

## 🎧 5. Padrões de Áudio e WebRTC (LiveKit)

1. **Gerenciamento de Ciclo de Vida (*Lifecycle*):**
   - Sempre desconectar e liberar recursos de tracks de áudio/vídeo (`room.disconnect()`, `dispose()`) ao sair de canais ou destruir widgets.
   - Evitar vazamento de memória mantendo referências a `Room` ou `Participant` após desconexão.
2. **Qualidade de Voz e Otimização:**
   - Habilitar **DTX** (*Discontinuous Transmission*) e **VAD** (*Voice Activity Detection*) para economizar largura de banda.
   - Taxa padrão de áudio recomendada: **Opus a 32–48 kbps**.
3. **Push-to-Talk (PTT):**
   - No Desktop, gerenciar teclas com `hotkey_manager` garantindo `HotKeyScope.system``.
   - Manter fallback para detecção de atividade de voz quando PTT estiver desativado.

---

## 🖥️ 6. Compartilhamento de Tela (WebRTC P2P Mesh & Go Signaling)

O ProjectNBX implementa uma arquitetura híbrida e modular para transmissão de vídeo e tela:

```text
                         ProjectNBX
                             │
              ┌──────────────┴──────────────┐
              │                             │
            VOICE                      SCREEN SHARE
              │                             │
           LiveKit                  ScreenShareTransport
              │                             │
         Áudio / Voz                   WebRTC P2P Mesh
                                            │
                                  ┌─────────┴─────────┐
                                  │                   │
                              Signaling             Media
                                  │                   │
                              Go Backend              P2P
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                Auth/Authz     State         Routing
                    │             │             │
                              In-memory       Local WS
                              (agora)         (agora)
                                  │               │
                               Redis         Redis Pub/Sub
                              (futuro)        (futuro)
```

### 🎯 6.1 Princípios Arquiteturais e Regras de Coexistência
1. **Preservação Absoluta da Voz (LiveKit Intocado):**
   - A comunicação de áudio/voz permanece **100% no LiveKit SFU**.
   - O compartilhamento de tela opera em um pipeline **completamente independente** via `ScreenShareTransport`.
   - Iniciar, pausar, reconectar ou encerrar o screen share **jamais interfere na conexão de voz ativa**.
2. **Backend Go como Signaling / Control Plane Puro (Zero Tráfego de Mídia):**
   - O servidor Go **NÃO transporta, processa, codifica ou retransmite vídeo**.
   - O Go é responsável exclusivamente por: Autenticação JWT, Autorização Anti-BOLA, Sinalização WebSocket (`WEBRTC_OFFER`, `WEBRTC_ANSWER`, `WEBRTC_ICE_CANDIDATE`), State Machine de Sessão, Rate Limiting e Geração de credenciais efêmeras TURN RFC 5766.
3. **Desacoplamento e Escalabilidade (Redis-Ready):**
   - O gerenciamento de estado no Go é isolado através da interface `ScreenShareRepository` (`InMemoryScreenShareRepository` com lock atômico via `sync.RWMutex`, pronto para substituição futura por Redis).
   - O roteamento de sinalização é isolado pela interface `SignalingRouter`.

### 🛡️ 6.2 Segurança, Anti-Spoofing e Pipeline Anti-BOLA (P0)
- **Prevenção de Impersonation:** O campo `from_user_id` enviado pelo cliente é sempre **ignorado** pelo servidor. O remetente é injetado com autoridade exclusiva a partir da sessão WebSocket autenticada (`client.UserID`).
- **Validação de Mensagens em 5 Etapas:**
  1. *Autenticação:* Remetente possui token JWT válido.
  2. *Matrícula de Canal:* O `channel_id` é validado como claim contra a presença do usuário registrada no WebSocket Hub. O `session.ChannelID` no repositório é a autoridade.
  3. *Validação de Destinatário:* `to_user_id` está ativo e presente no mesmo canal.
  4. *Correspondência de Sessão:* `session_id` pertence ao canal e está no estado `ACTIVE`.
  5. *Autoridade de Encerramento:* `SCREEN_SHARE_STOP` é processado estritamente se `client.UserID == session.BroadcasterID`.
- **Token Bucket Rate Limiting:**
  - `WEBRTC_OFFER` / `WEBRTC_ANSWER`: 10 ops/s (burst 15).
  - `WEBRTC_ICE_CANDIDATE`: 100 ops/s (burst 150) — *sem ordenação artificial de sequence*.
  - `SCREEN_SHARE_START`: 5 ops/min.
  - `SCREEN_SHARE_JOIN`: 15 ops/min.
  - Limite de buffer: SDP $\le$ 64 KB, ICE Candidate $\le$ 4 KB.
- **Capacidade Atômica (`AddViewerIfCapacity`):**
  - Limite de espectadores: `MAX_SCREEN_VIEWERS = 5` (configurável via `ScreenShareConfig`), prevenindo saturação de uplink e encoder no transmissor.
- **Grace Period Temporal (10s):**
  - Quando o host oscila a conexão, a sessão permanece com `State == ACTIVE` e `GraceUntil = now + 10s`.
  - Se o host reconectar dentro da janela, o grace period é cancelado e os espectadores continuam assistindo normalmente. Se expirar, a sessão é finalizada e os espectadores são notificados.

### 🌐 6.3 WebRTC P2P Mesh no Flutter
- **Contratos Plugáveis:**
  - `ScreenCaptureSource`: Abstração para captura de monitores e janelas (`DesktopScreenCaptureSource` com `DesktopCapturer`).
  - `ScreenShareTransport`: Abstração de rede (`P2PWebRTCScreenTransport` usando `flutter_webrtc`, permitindo plugar SFU no futuro sem alterar a UI).
  - `ScreenShareController`: Gerenciamento reativo via Riverpod (`StateNotifier<ScreenShareState>`).
- **Padrão Perfect Negotiation:**
  - Broadcaster: Peer `impolite` (`polite = false`) — inicia a oferta após o evento `SCREEN_SHARE_VIEWER_JOINED`.
  - Viewer: Peer `polite` (`polite = true`) — responde com Answer e realiza rollback em colisões.
- **Resiliência e Recuperação:**
  - ICE Restart automático com limite de 3 tentativas (`MAX_ICE_RESTART_ATTEMPTS = 3`).
  - Endpoint de credenciais temporárias TURN: `GET /api/v1/webrtc/turn-credentials` (RFC 5766 HMAC-SHA1, TTL 1h). O Flutter nunca armazena secrets estáticos.
- **Perfis de Qualidade Alvo (Target Configurations):**
  - 🌿 **Low / Econômico:** 720p @ 20 FPS (~1.2 Mbps) — Código e texto.
  - ⚖️ **Medium / Balanceado:** 1080p @ 30 FPS (~3.0 Mbps) — Apresentações e padrão geral.
  - 🚀 **High / Fluidez:** 1080p @ 60 FPS (~6.0 Mbps) — Vídeos e alta movimentação.
- **Interface e Experiência do Usuário:**
  - `ScreenPickerDialog`: Modal com prévias/thumbnails de monitores e janelas abertas e seleção de perfil no início.
  - `ScreenShareView`: Renderizador `RTCVideoRenderer` com modo cinema/foco, overlay de controles no hover, ajuste de aspect ratio e métricas de conexão em tempo real ($P_{50} / P_{95}$ RTT e perda de pacotes).

---

## 📦 7. Convenções de Código, Linter e Formatação

### 🚫 Regra de Imports no Flutter
- **PROIBIDO o uso de imports relativos** (ex: `import '../../../core/...'`).
- **SEMPRE utilizar imports absolutos de pacote:** `import 'package:projectnbx/...'`.
- Esta regra é fiscalizada estritamente pelo linter via `always_use_package_imports` e `directives_ordering` no [analysis_options.yaml](file:///d:/Github/My/projectNBX/analysis_options.yaml).

### 📐 Formatação e Linters
- **Prettier:** Configurado via [.prettierrc](file:///d:/Github/My/projectNBX/.prettierrc) e [.prettierignore](file:///d:/Github/My/projectNBX/.prettierignore) (LF, 2 espaços, single quotes).
- **EditorConfig:** Configurado via [.editorconfig](file:///d:/Github/My/projectNBX/.editorconfig).
- **Go Linter:** Regras do GolangCI-Lint definidas em [backend/.golangci.yml](file:///d:/Github/My/projectNBX/backend/.golangci.yml).
- **VS Code:** Auto-format e auto-organize imports configurados em [.vscode/settings.json](file:///d:/Github/My/projectNBX/.vscode/settings.json).

### 📝 Padrão de Mensagens de Commit
Todas as mensagens de commit devem seguir estritamente a seguinte estrutura:

```text
FIX | FEAT | CHORE: mensagem do commit

Descrição detalhada explicando o que foi implementado ou corrigido.

Closes #123
```

- **Linha de Título (Subject):**
  - Deve ser concisa e iniciar obrigatoriamente com o tipo em caixa alta seguido de dois-pontos: `FIX: `, `FEAT: ` ou `CHORE: `.
  - **FIX:** Correções de bugs, falhas ou comportamentos inconsistentes.
  - **FEAT:** Desenvolvimento e entrega de novas funcionalidades ou telas.
  - **CHORE:** Tarefas de manutenção, documentação, dependências, linters ou refatorações estruturais.
  - **NUNCA incluir `closes #123` no título da mensagem.**
- **Corpo do Commit (Descrição Obrigatória):**
  - Separado do título por uma linha em branco.
  - Deve conter um resumo claro e explicativo dos pontos alterados.
- **Referência à Issue (`Closes #123`):**
  - Deve estar **obrigatoriamente no corpo/descrição do commit** (ao final), e **nunca no título**.

---

## 🔍 8. Qualidade de Código e SonarQube / SonarCloud

- **Configuração do Sonar:** Definida em [sonar-project.properties](file:///d:/Github/My/projectNBX/sonar-project.properties) cobrindo tanto Flutter (`lib`, `test`) quanto Go (`backend`).
- **Cobertura de Código (Coverage):**
  - Flutter: `flutter test --coverage` gerando `coverage/lcov.info`.
  - Go: `go test -coverprofile=coverage.out ./...`.
- **CI/CD:** Pipeline automatizado no GitHub Actions em [.github/workflows/sonar.yml](file:///d:/Github/My/projectNBX/.github/workflows/sonar.yml).
- **Script Local:** Para rodar a análise localmente via Docker, execute `.\scripts\run_sonar_analysis.ps1`.

---

## 🛡️ 9. Boas Práticas Operacionais

- **Zero Warnings:** Executar `flutter analyze` e garantir 0 warnings antes de qualquer commit ou entrega.
- **Segurança:** Nunca comitar senhas, chaves de API do LiveKit ou segredos JWT hardcoded.
- **Testes Automatizados:** Manter testes de unidade e widget para todos os novos fluxos e controllers.
- **Testes de Concorrência em Go:** Sempre validar pacotes concorrentes com `go test -race ./...`.

---

## 🛠️ 10. Diretrizes de Execução do Agente e Uso de Ferramentas

### 🚫 Restrição Estrita de Edição via Shell / Terminal
- **PROIBIDO usar comandos de terminal/shell (`cmd.exe`, PowerShell, bash, `sed`, `awk`, `echo`, `patch`, `Write-Output`, `[System.IO.File]::WriteAllText`, scripts Python/Node ou redirecionamentos)** para criar, sobrescrever ou alterar arquivos do projeto.
- **SEMPRE utilizar as ferramentas nativas de edição de arquivo da IDE / Agent (`apply_diff`, `edit_file`, `write_file`)**, garantindo que as alterações passem pelo visualizador de *diff* do GoLand e do AndroidStudio para aprovação granular (pedaço por pedaço) pelo desenvolvedor.
- O terminal só deve ser utilizado para **leitura/diagnóstico e execução de ferramentas de compilação/teste**, como:
  - `go test ./...`, `go vet ./...`, `golangci-lint run`
  - `flutter analyze`, `flutter test`
  - Comandos do Docker (`docker compose ps`, etc.)

### 🧩 Edições Estruturadas e Diffs
- Não faça substituições cegas do arquivo inteiro (*full file overwrite*) quando apenas um trecho ou método específico for solicitado.
- Preserve comentários, estruturas existentes e formatações locais ao propor edições parciais.
- Antes de concluir uma tarefa, valide se os arquivos alterados seguem a formatação oficial (`gofmt` / `dart format`).

---
