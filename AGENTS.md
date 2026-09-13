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

### 🌑 Modo Escuro (*Pastel Tech Aesthetic*)
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
   - No Desktop, gerenciar teclas com `hotkey_manager` garantindo `HotKeyScope.system`.
   - Manter fallback para detecção de atividade de voz quando PTT estiver desativado.

---

## 📦 6. Convenções de Código, Linter e Formatação

### 🚫 Regra de Imports no Flutter
- **PROIBIDO o uso de imports relativos** (ex: `import '../../../core/...'`).
- **SEMPRE utilizar imports absolutos de pacote:** `import 'package:projectnbx/...'`.
- Esta regra é fiscalizada estritamente pelo linter via `always_use_package_imports` e `directives_ordering` no [analysis_options.yaml](file:///d:/Github/My/projectNBX/analysis_options.yaml).

### 📐 Formatação e Linters
- **Prettier:** Configurado via [.prettierrc](file:///d:/Github/My/projectNBX/.prettierrc) e [.prettierignore](file:///d:/Github/My/projectNBX/.prettierignore) (LF, 2 espaços, single quotes).
- **EditorConfig:** Configurado via [.editorconfig](file:///d:/Github/My/projectNBX/.editorconfig).
- **Go Linter:** Regras do GolangCI-Lint definidas em [backend/.golangci.yml](file:///d:/Github/My/projectNBX/backend/.golangci.yml).
- **VS Code:** Auto-format e auto-organize imports configurados em [.vscode/settings.json](file:///d:/Github/My/projectNBX/.vscode/settings.json).

---

## 🔍 7. Qualidade de Código e SonarQube / SonarCloud

- **Configuração do Sonar:** Definida em [sonar-project.properties](file:///d:/Github/My/projectNBX/sonar-project.properties) cobrindo tanto Flutter (`lib`, `test`) quanto Go (`backend`).
- **Cobertura de Código (Coverage):**
  - Flutter: `flutter test --coverage` gerando `coverage/lcov.info`.
  - Go: `go test -coverprofile=coverage.out ./...`.
- **CI/CD:** Pipeline automatizado no GitHub Actions em [.github/workflows/sonar.yml](file:///d:/Github/My/projectNBX/.github/workflows/sonar.yml).
- **Script Local:** Para rodar a análise localmente via Docker, execute `.\scripts\run_sonar_analysis.ps1`.

---

## 🛡️ 8. Boas Práticas Operacionais

- **Zero Warnings:** Executar `flutter analyze` e garantir 0 warnings antes de qualquer commit ou entrega.
- **Segurança:** Nunca comitar senhas, chaves de API do LiveKit ou segredos JWT hardcoded.
- **Testes Automatizados:** Manter testes de unidade e widget para todos os novos fluxos e controllers.
