import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/shortcuts/models/shortcut_combination.dart';

enum ShortcutCategory {
  voice('Áudio & Transmissão', LucideIcons.mic),
  navigation('Navegação & Interface', LucideIcons.compass),
  servers('Servidores & Comunidade', LucideIcons.server),
  chat('Chat & Mensagens', LucideIcons.messageSquare),
  system('Aparência & Sistema', LucideIcons.settings);

  final String label;
  final IconData icon;
  const ShortcutCategory(this.label, this.icon);
}

enum AppShortcutAction {
  // --- 1. Áudio & Transmissão ---
  toggleMute(
    id: 'voice.toggle_mute',
    title: 'Mutar / Desmutar Microfone',
    description: 'Ativa ou silencia o microfone em qualquer tela do app.',
    category: ShortcutCategory.voice,
    icon: LucideIcons.mic,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x0000006d, // 'm'
      keyLabel: 'M',
    ),
  ),

  toggleDeafen(
    id: 'voice.toggle_deafen',
    title: 'Ativar / Desativar Áudio (Ensurdecer)',
    description: 'Silencia a saída de som e o microfone simultaneamente.',
    category: ShortcutCategory.voice,
    icon: LucideIcons.headphones,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000064, // 'd'
      keyLabel: 'D',
    ),
  ),

  disconnectVoice(
    id: 'voice.disconnect',
    title: 'Desconectar da Chamada de Voz',
    description: 'Encerra a chamada e sai do canal de voz ativo.',
    category: ShortcutCategory.voice,
    icon: LucideIcons.phoneOff,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000065, // 'e'
      keyLabel: 'E',
    ),
  ),

  toggleScreenShare(
    id: 'stream.toggle_share',
    title: 'Compartilhar Tela / Parar Transmissão',
    description: 'Abre o seletor de tela/janela ou para a live atual.',
    category: ShortcutCategory.voice,
    icon: LucideIcons.screenShare,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000073, // 's'
      keyLabel: 'S',
    ),
  ),

  toggleFullscreenStream(
    id: 'stream.toggle_fullscreen',
    title: 'Alternar Tela Cheia na Transmissão',
    description: 'Expande ou restaura o palco de transmissão de vídeo.',
    category: ShortcutCategory.voice,
    icon: LucideIcons.maximize2,
    defaultCombination: ShortcutCombination(
      keyId: 0x0010000007a, // F11
      keyLabel: 'F11',
    ),
  ),

  toggleStreamAudio(
    id: 'stream.toggle_audio',
    title: 'Silenciar / Ouvir Transmissão Ao Vivo',
    description: 'Ativa ou desativa o áudio do stream que está assistindo.',
    category: ShortcutCategory.voice,
    icon: LucideIcons.volumeX,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000075, // 'u'
      keyLabel: 'U',
    ),
  ),

  quickAudioDevices(
    id: 'voice.quick_devices',
    title: 'Menu Rápido de Dispositivos de Áudio',
    description: 'Abre a seleção rápida de microfone ou fones.',
    category: ShortcutCategory.voice,
    icon: LucideIcons.sliders,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000061, // 'a'
      keyLabel: 'A',
    ),
  ),

  // --- 2. Navegação & Interface ---
  navigateHome(
    id: 'nav.home',
    title: 'Ir para o Início (Hub Principal)',
    description: 'Retorna imediatamente para o feed inicial de servidores.',
    category: ShortcutCategory.navigation,
    icon: LucideIcons.house,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      keyId: 0x00000068, // 'h'
      keyLabel: 'H',
    ),
  ),

  quickSearch(
    id: 'nav.quick_search',
    title: 'Busca Rápida de Servidores',
    description: 'Foca na barra de pesquisa para filtrar servidores rapidamente.',
    category: ShortcutCategory.navigation,
    icon: LucideIcons.search,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      keyId: 0x0000006b, // 'k'
      keyLabel: 'K',
    ),
  ),

  toggleRightSidebar(
    id: 'nav.toggle_sidebar',
    title: 'Recolher / Expandir Painel Lateral',
    description: 'Alterna a visibilidade da barra de canais e membros.',
    category: ShortcutCategory.navigation,
    icon: LucideIcons.panelRight,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      keyId: 0x00000062, // 'b'
      keyLabel: 'B',
    ),
  ),

  toggleChatHud(
    id: 'nav.toggle_chat_hud',
    title: 'Alternar Overlay de Chat Flutuante',
    description: 'Exibe ou esconde o HUD flutuante de mensagens sobre a live.',
    category: ShortcutCategory.navigation,
    icon: LucideIcons.messageSquareDashed,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000068, // 'h'
      keyLabel: 'H',
    ),
  ),

  openSettings(
    id: 'nav.open_settings',
    title: 'Abrir Configurações',
    description: 'Abre a central de preferências de conta, áudio e atalhos.',
    category: ShortcutCategory.navigation,
    icon: LucideIcons.settings,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      keyId: 0x0000002c, // ','
      keyLabel: ',',
    ),
  ),

  closeOrEscape(
    id: 'nav.close_escape',
    title: 'Fechar Modal / Voltar',
    description: 'Fecha o diálogo aberto ou retorna da tela atual.',
    category: ShortcutCategory.navigation,
    icon: LucideIcons.x,
    defaultCombination: ShortcutCombination(
      keyId: 0x0010000001b, // Escape
      keyLabel: 'Esc',
    ),
  ),

  // --- 3. Servidores & Comunidade ---
  openCreateServer(
    id: 'server.create',
    title: 'Criar Novo Servidor',
    description: 'Abre o diálogo de criação de comunidade ou entrada por código.',
    category: ShortcutCategory.servers,
    icon: LucideIcons.circlePlus,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x0000006e, // 'n'
      keyLabel: 'N',
    ),
  ),

  openInviteDialog(
    id: 'server.invite',
    title: 'Convidar Pessoas para o Servidor',
    description: 'Gera e copia links de convite para amigos entrarem.',
    category: ShortcutCategory.servers,
    icon: LucideIcons.userPlus,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      keyId: 0x00000069, // 'i'
      keyLabel: 'I',
    ),
  ),

  openServerRoles(
    id: 'server.roles',
    title: 'Gerenciar Cargos do Servidor',
    description: 'Abre o painel de criação e atribuição de cargos.',
    category: ShortcutCategory.servers,
    icon: LucideIcons.shieldCheck,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000072, // 'r'
      keyLabel: 'R',
    ),
  ),

  openJoinRequests(
    id: 'server.join_requests',
    title: 'Ver Solicitações de Entrada',
    description: 'Gerencia os pedidos de entrada pendentes no servidor.',
    category: ShortcutCategory.servers,
    icon: LucideIcons.inbox,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x0000006a, // 'j'
      keyLabel: 'J',
    ),
  ),

  // --- 4. Chat & Mensagens ---
  focusChatInput(
    id: 'chat.focus_input',
    title: 'Focar Campo de Envio de Mensagem',
    description: 'Coloca o cursor no campo de texto para digitar.',
    category: ShortcutCategory.chat,
    icon: LucideIcons.messageSquarePlus,
    defaultCombination: ShortcutCombination(
      alt: true,
      keyId: 0x00000063, // 'c'
      keyLabel: 'C',
    ),
  ),

  attachFile(
    id: 'chat.attach_file',
    title: 'Adicionar Anexo ao Chat',
    description: 'Abre a caixa de seleção de arquivos para envio.',
    category: ShortcutCategory.chat,
    icon: LucideIcons.paperclip,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000066, // 'f'
      keyLabel: 'F',
    ),
  ),

  toggleEmojiPicker(
    id: 'chat.toggle_emoji',
    title: 'Abrir Seletor de Emojis',
    description: 'Abre a biblioteca de reações e emojis para o chat.',
    category: ShortcutCategory.chat,
    icon: LucideIcons.smile,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      keyId: 0x00000065, // 'e'
      keyLabel: 'E',
    ),
  ),

  // --- 5. Aparência & Sistema ---
  toggleTheme(
    id: 'system.toggle_theme',
    title: 'Alternar Tema Claro / Escuro',
    description: 'Muda instantaneamente o esquema de cores da aplicação.',
    category: ShortcutCategory.system,
    icon: LucideIcons.sunMoon,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000074, // 't'
      keyLabel: 'T',
    ),
  ),

  checkForUpdates(
    id: 'system.check_updates',
    title: 'Verificar Atualizações do Sistema',
    description: 'Consulta o servidor em busca de novas versões do ProjectNBX.',
    category: ShortcutCategory.system,
    icon: LucideIcons.refreshCw,
    defaultCombination: ShortcutCombination(
      ctrl: true,
      shift: true,
      keyId: 0x00000070, // 'p'
      keyLabel: 'P',
    ),
  ),

  logout(
    id: 'system.logout',
    title: 'Sair da Conta (Logout)',
    description: 'Encerra a sessão e desconecta o usuário.',
    category: ShortcutCategory.system,
    icon: LucideIcons.logOut,
    defaultCombination: null, // Default off for safety, but user can customize!
  );

  final String id;
  final String title;
  final String description;
  final ShortcutCategory category;
  final IconData icon;
  final ShortcutCombination? defaultCombination;

  const AppShortcutAction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    this.defaultCombination,
  });

  static AppShortcutAction? fromId(String id) {
    for (final action in AppShortcutAction.values) {
      if (action.id == id) return action;
    }
    return null;
  }
}
