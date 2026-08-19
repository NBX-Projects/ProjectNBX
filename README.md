# 🚀 ProjectNBX

<div align="center">
  <img src="assets/logo.png" alt="ProjectNBX Logo" width="128" height="128" />
  <h3>Plataforma de Comunicação e Voz Cross-Platform para Desenvolvedores e Gamers</h3>
  <p>Uma alternativa moderna, self-hosted e ultra leve ao Discord, construída em <b>Flutter</b> com <b>LiveKit (WebRTC SFU)</b>.</p>
</div>

---

## 📌 Visão Geral

O **ProjectNBX** é um aplicativo multiplataforma projetado para grupos e comunidades que buscam alta performance, controle dos próprios dados e latência ultrabaixa em chamadas de voz e compartilhamento de tela.

### 🌟 Destaques
- **Multiplataforma Unificado:** Uma única base de código Flutter rodando em **Windows**, **Linux**, **macOS**, **Android**, **iOS** e **Web**.
- **Áudio de Alta Fidelidade & Baixa Latência:** Alimentado por **LiveKit SFU (WebRTC)** com suporte a DTX (Discontinuous Transmission), cancelamento de ruído e eco.
- **Push-to-Talk Global no Desktop:** Atalhos de teclado que funcionam mesmo com jogos em tela cheia (`hotkey_manager`).
- **Bandeja do Sistema (*System Tray*):** Continue na chamada sem poluir a barra de tarefas ao fechar a janela principal (`tray_manager`).
- **Background Voice no Mobile:** Chamadas ativas em segundo plano no Android (*Foreground Service*) e iOS (*VoIP/Audio Background Modes*).
- **Compartilhamento de Tela:** Transmissão de janelas ou monitores completos em alta taxa de quadros (30/60 fps).

---

## 🏗️ Arquitetura & Stack Tecnológica

| Componente | Tecnologia | Descrição |
| :--- | :--- | :--- |
| **Frontend / Cliente** | Flutter (Dart 3.x) | Interface responsiva e nativa para todas as plataformas |
| **Engine de Mídia** | LiveKit WebRTC (`livekit_client`) | Servidor SFU para roteamento escalável de áudio e vídeo |
| **Atalhos & Janela** | `hotkey_manager` + `tray_manager` | Controle nativo do sistema operacional (Desktop) |
| **Sinalização & Chat** | WebSockets / REST API | Mensagens em tempo real, presença e canais de texto |

---

## 🚀 Como Executar Localmente

### Pré-requisitos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado (`3.x` ou superior).
- Compiladores da plataforma desejada (Visual Studio com C++ para Windows, Xcode para macOS/iOS, Android Studio para Android).

### 1. Clonar e Instalar Dependências
```bash
git clone https://github.com/tauisilva/projectNBX.git
cd projectNBX
flutter pub get
```

### 2. Executar no Desktop (Windows / Linux / macOS)
```bash
# Executar no Windows
flutter run -d windows

# Executar no macOS
flutter run -d macos

# Executar no Linux
flutter run -d linux
```

### 3. Executar no Mobile
```bash
# Listar dispositivos conectados
flutter devices

# Executar no dispositivo conectado ou emulador
flutter run
```

---

## 📦 Build e Empacotamento

```bash
# Gerar executável para Windows (.exe)
flutter build windows --release

# Gerar APK ou App Bundle para Android
flutter build apk --release
flutter build appbundle --release

# Gerar build Web
flutter build web --release
```

---

## 📄 Licença

Distribuído sob a licença MIT. Consulte `LICENSE` para mais detalhes.
