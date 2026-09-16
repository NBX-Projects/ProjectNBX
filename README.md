# 🚀 ProjectNBX

<div align="center">
  <img src="assets/logo.png" alt="ProjectNBX Logo" width="128" height="128" />
  <h3>Plataforma de Comunicação e Voz Cross-Platform para Desenvolvedores e Gamers</h3>
  <p>Uma alternativa moderna, self-hosted e ultra leve ao Discord, construída em <b>Flutter</b> com <b>LiveKit (WebRTC SFU)</b> e backend em <b>Go</b>.</p>

  <p>
    <a href="https://nbx-projects.github.io/ProjectNBX/"><img src="https://img.shields.io/badge/Acessar-Web%20App%20(GitHub%20Pages)-2D6A4F?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Web App" /></a>
    <a href="https://github.com/NBX-Projects/ProjectNBX/releases/latest"><img src="https://img.shields.io/badge/Baixar-Releases%20(.exe%20%7C%20.apk)-181926?style=for-the-badge&logo=github&logoColor=white" alt="Releases" /></a>
  </p>
</div>

---

## 🌐 Acesso Rápido & Downloads

- 🌍 **Versão de Navegador (GitHub Pages):** [https://nbx-projects.github.io/ProjectNBX/](https://nbx-projects.github.io/ProjectNBX/)
- 🪟 **Instalador Windows (`.exe`):** Baixe em [Releases](https://github.com/NBX-Projects/ProjectNBX/releases/latest) (com auto-atualizador integrado)
- 📱 **Instalador Android (`.apk`):** Baixe em [Releases](https://github.com/NBX-Projects/ProjectNBX/releases/latest)

---

## 📖 Documentação & Guias

- 🚀 **[Guia Passo a Passo de Inicialização (GETTING_STARTED.md)](GETTING_STARTED.md)**
- 🤖 **[Diretrizes de Arquitetura para Agentes & Devs (AGENTS.md)](AGENTS.md)**
- 🎨 **[Protótipo no Figma (UX-NBX)](https://www.figma.com/make/ZFTQctJ9RrvmF2cPd2BINo/UX-NBX?t=jGh4g2lVq1tvnQ5E-1)**

---

## 📌 Visão Geral

O **ProjectNBX** é um ecossistema de colaboração e voz em tempo real projetado para comunidades, desenvolvedores e gamers que buscam alto desempenho, soberania de dados e latência ultrabaixa em chamadas de voz e compartilhamento de tela.

### 🌟 Destaques e Funcionalidades

- **Multiplataforma Unificado:** Uma única base de código Flutter moderna rodando em **Windows**, **Linux**, **macOS**, **Android**, **iOS** e **Web**.
- **Áudio de Alta Fidelidade & Baixa Latência:** Alimentado por **LiveKit SFU (WebRTC)** com suporte a DTX (*Discontinuous Transmission*), VAD (*Voice Activity Detection*), cancelamento de ruído e eco.
- **Compartilhamento de Tela Nativo e Responsivo:** 
  - Enumeração e captura em tempo real de monitores inteiros e janelas reais de aplicativos no Windows via Win32 / Desktop Window Manager (DWM).
  - Miniaturas ao vivo (previews) com alta qualidade antes de iniciar a transmissão.
  - Filtragem inteligente de processos internos de sistema e janelas suspensas/camufladas (*Cloaked Windows*).
  - Configuração de qualidade sob demanda: 720p, 1080p HD, 1440p 2K a 15, 30 ou 60 FPS com áudio do sistema em conjunto (48kHz).
- **Canais Híbridos (Texto + Voz + Streaming):** Alternância dinâmica entre chat direto, visualização em grid de participantes e HUD imersivo de transmissão.
- **Design System Exclusivo:** Identidade visual inspirada em estética de terminal/desenvolvedor com materiais táteis:
  - 🌑 **Modo Escuro (*Pastel Tech*):** Deep Matte Charcoal (`#181926`), Warm Pastel Peach e acentos sutis.
  - ☀️ **Modo Claro (*Forest Slate*):** Alabaster Cream (`#FAF9F6`), Forest Sage e Slate Blue.
- **Push-to-Talk Global no Desktop:** Atalhos de sistema que funcionam mesmo com jogos ou softwares em tela cheia (`hotkey_manager`).
- **Bandeja do Sistema (*System Tray*):** Continue na chamada em segundo plano sem poluir a barra de tarefas ao minimizar ou fechar a janela principal (`tray_manager`).
- **Background Voice no Mobile:** Chamadas ativas em segundo plano no Android (*Foreground Service*) e iOS (*VoIP/Audio Background Modes*).
- **Backend Robusto em Go:** Microserviço com PostgreSQL 16 persistente, Redis 7, JWT e WebSocket Hub para presença, chat e eventos em tempo real.

---

## 🛠️ Tecnologias e Arquitetura

| Camada | Tecnologia | Detalhes |
| :--- | :--- | :--- |
| **Frontend** | Flutter 3.24+ / Dart 3.5+ | Feature-First Architecture, Riverpod, Google Fonts |
| **Backend** | Go 1.22+ | Gorilla Mux, JWT, WebSocket Hub |
| **Banco de Dados** | PostgreSQL 16 | Migrações SQL versionadas, Auditoria e Enums |
| **Cache & Presença** | Redis 7 | Pub/Sub e cache de sessão |
| **WebRTC & Voz** | LiveKit SFU | Latência < 50ms, DTX, Opus 48kbps |
| **Infraestrutura** | Docker Compose | Orquestração local completa de banco, cache e SFU |

---

## 🚀 Como Executar o Projeto

### 1. Iniciar os Serviços de Backend (Docker)

```bash
cd backend
docker compose up -d
```

Isso inicializará automaticamente o **PostgreSQL 16**, o **Redis 7** e o **LiveKit SFU**.

### 2. Iniciar o Frontend Flutter

Na raiz do repositório:

```bash
# Obter as dependências do Flutter
flutter pub get

# Executar no Windows (Desktop)
flutter run -d windows
```

> **Dica:** Durante a execução no Windows, pressione `r` no terminal para **Hot Reload** ou `R` para **Hot Restart**.

---

## 📱 Execução em Outras Plataformas

```bash
# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Web (Chrome / Edge)
flutter run -d chrome

# Android / iOS (com emulador ou dispositivo conectado)
flutter run
```

---

## 📦 Build e Empacotamento de Produção

O projeto suporta **Flavors** e arquivos de configuração de ambiente (`.env`):

```bash
# Executável para Windows Desktop
flutter build windows --release --dart-define-from-file=.env.prod

# APK Android com Flavor de Produção
flutter build apk --flavor prod --dart-define-from-file=.env.prod --release

# APK Android com Flavor de Desenvolvimento
flutter build apk --flavor dev --dart-define-from-file=.env.dev --release

# Build Web (GitHub Pages com base-href)
flutter build web --release --base-href "/ProjectNBX/" --dart-define-from-file=.env.prod
```

### 🏷️ Distribuição Automatizada (GitHub Actions)
Ao criar e enviar uma tag Git (ex: `v1.0.1`), três workflows independentes no GitHub Actions geram e publicam automaticamente os artefatos:
- **Windows (`build-windows.yml`)**: Gera o instalador unificado `ProjectNBX-Setup-<tag>-windows.exe` (via Inno Setup) e zip portátil.
- **Android (`build-android.yml`)**: Gera o APK `ProjectNBX-<tag>-android.apk`.
- **Web (`deploy-web.yml`)**: Compila e faz deploy automático no **GitHub Pages**.

---

## 🔍 Qualidade de Código e Análise Sonar

O projeto adota padrões estritos de qualidade e cobertura (Zero Warnings):

```bash
# Executar o linter do Flutter
flutter analyze

# Executar os testes automatizados
flutter test

# Executar análise SonarQube localmente (requer Docker)
.\scripts\run_sonar_analysis.ps1
```

---

## 📄 Licença

Distribuído sob a licença MIT. Consulte `LICENSE` para mais detalhes.
