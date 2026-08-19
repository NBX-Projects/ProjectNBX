# 🤖 AGENTS.md — Diretrizes de Desenvolvimento e Automação

Este documento define padrões de arquitetura, convenções de código e diretrizes operacionais para Agentes de IA e desenvolvedores que trabalham na base de código do **ProjectNBX**.

---

## 🎯 1. Visão do Projeto e Escopo

O **ProjectNBX** é um cliente de comunicação multiplataforma (Discord-like) focado em devs e gamers.
* **Metas de Performance:** Baixo consumo de memória (< 80 MB em Desktop), áudio de latência ultrabaixa (< 50 ms) e responsividade fluida.
* **Plataformas Alvo:** Windows, macOS, Linux, Android, iOS e Web a partir de uma base de código Flutter unificada.

---

## 🏛️ 2. Estrutura de Diretórios Recomendada

A organização de código em `lib/` deve seguir uma arquitetura orientada a módulos (*Feature-First*):

```
lib/
├── core/                       # Utilitários compartilhados, temas, constantes e rede
│   ├── constants/              # URLs, configurações de áudio e layouts
│   ├── network/                # Clientes HTTP / WebSocket
│   ├── theme/                  # Design System (Dark mode, cores, tipografia)
│   └── utils/                  # Formatadores e helpers
├── features/                   # Módulos isolados por funcionalidade
│   ├── auth/                   # Autenticação e sessão do usuário
│   ├── chat/                   # Canais de texto e mensagens em tempo real
│   ├── servers/                # Lista de servidores, categorias e canais
│   ├── voice/                  # WebRTC, LiveKit rooms, PTT e áudio
│   │   ├── controllers/        # Gerenciamento de estado da sala de voz
│   │   ├── services/           # Integração com LiveKit e WebRTC
│   │   └── widgets/            # UI dos canais de voz e grids de participantes
│   └── settings/               # Configurações de áudio, microfone, atalhos e tema
├── platform/                   # Lógicas específicas de sistema operacional
│   ├── desktop/                # Hotkeys globais, Tray e Window Manager
│   └── mobile/                 # Foreground services e background audio
└── main.dart                   # Inicialização e injeção de dependências
```

---

## 🎧 3. Padrões de Áudio e WebRTC (LiveKit)

1. **Gerenciamento de Ciclo de Vida (*Lifecycle*):**
   - Sempre desconectar e liberar recursos de tracks de áudio/vídeo (`room.disconnect()`, `dispose()`) ao sair de canais ou destruir widgets.
   - Evitar vazamento de memória mantendo referências a `Room` ou `Participant` após desconexão.
2. **Qualidade de Voz e Otimização:**
   - Habilitar **DTX** (*Discontinuous Transmission*) e **VAD** (*Voice Activity Detection*) para economizar largura de banda.
   - Taxa padrão de áudio recomendada: **Opus a 32–48 kbps** (ideal para voz nítida com baixo overhead).
3. **Push-to-Talk (PTT):**
   - No Desktop, gerenciar teclas com `hotkey_manager` garantindo `HotKeyScope.system`.
   - Manter fallback para detecção de atividade de voz quando PTT estiver desativado.

---

## 💻 4. Regras para Desktop e Mobile

- **Desktop (Windows / Linux / macOS):**
  - Tratar o evento de fechar a janela (`window_manager`) para minimizar para o *System Tray* quando o usuário estiver em uma chamada ativa.
  - Testar compatibilidade de atalhos e certificar-se de não bloquear teclas reservadas do sistema operacional.
- **Mobile (Android / iOS):**
  - Manter notificações persistentes durante chamadas ativas em segundo plano.
  - Respeitar permissões de microfone solicitadas em tempo de execução (`permission_handler`).

---

## 🎨 5. Padrões de Interface e Estilo (Design System)

- **Tema:** Dark mode como padrão principal (estética moderna, contrastes adequados e tipografia limpa).
- **Feedback Visual de Voz:** Destacar participantes com borda verde/brilhante quando estiverem transmitindo áudio ativo (`isSpeaking`).
- **Assets:** Utilizar sempre o logo oficial em `assets/logo.png` para ícones e identidade visual.

---

## 🛠️ 6. Boas Práticas e Testes

- Não comitar tokens, chaves de API ou segredos nos arquivos de código ou `.env`.
- Executar `flutter analyze` e garantir zero warnings antes de novos commits.
- Manter testes de unidade e de widget para controllers e parsing de mensagens de chat.
