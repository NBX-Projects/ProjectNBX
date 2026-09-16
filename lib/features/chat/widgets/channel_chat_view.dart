import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/utils/chat_helpers.dart';
import 'package:projectnbx/features/chat/widgets/components/chat_bubble_components.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';
import 'package:projectnbx/features/voice/widgets/immersive_stream_player.dart';

class ChannelChatView extends StatelessWidget {
  final bool isDark;
  final String activeChannelName;
  final String channelKey;
  final String username;
  final List<ChatMessage> messages;
  final TextEditingController messageController;
  final TextEditingController editMessageController;
  final ScrollController scrollController;
  final FocusNode? messageFocusNode;
  final String? editingMessageId;
  final bool isTransmitting;
  final bool isInVoice;
  final bool isConnectingVoice;
  final bool isVoiceConnected;
  final bool isRightSidebarVisible;
  final Color accentColor;
  final VoiceParticipantInfo? activeBroadcaster;
  final VoidCallback onToggleTransmission;
  final VoidCallback onToggleVoiceChannel;
  final VoidCallback onToggleRightSidebar;
  final VoidCallback onWatchLive;
  final void Function(String channelKey, String author) onSendMessage;
  final void Function(String messageId) onStartEditing;
  final VoidCallback onCancelEditing;
  final void Function(String messageId) onSaveEditing;
  final void Function(String messageId) onDeleteMessage;
  final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants;
  final String? clientSessionId;

  const ChannelChatView({
    super.key,
    required this.isDark,
    required this.activeChannelName,
    required this.channelKey,
    required this.username,
    required this.messages,
    required this.messageController,
    required this.editMessageController,
    required this.scrollController,
    this.messageFocusNode,
    this.editingMessageId,
    required this.isTransmitting,
    required this.isInVoice,
    this.isConnectingVoice = false,
    this.isVoiceConnected = false,
    required this.isRightSidebarVisible,
    this.accentColor = const Color(0xFFF5CBA7),
    this.activeBroadcaster,
    required this.onToggleTransmission,
    required this.onToggleVoiceChannel,
    required this.onToggleRightSidebar,
    required this.onWatchLive,
    required this.onSendMessage,
    required this.onStartEditing,
    required this.onCancelEditing,
    required this.onSaveEditing,
    required this.onDeleteMessage,
    this.voiceParticipants = const {},
    this.clientSessionId,
  });

  List<VoiceParticipantInfo> get _channelVoiceParticipants {
    final map = voiceParticipants[channelKey];
    if (map == null) return [];
    return map.values.where((p) => p.isInVoice).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: isDark ? const Color(0xFF13141F) : const Color(0xFFFAF9F6),
      child: Column(
        children: [
          // 1. Channel Header Bar
          Container(
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141522) : const Color(0xFFFFFFFF),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF202234)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.hash, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          activeChannelName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: isMobile ? 14.5 : 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Canal Híbrido · Texto, Voz e Transmissão integrados',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : AppColors.lightTextMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (isInVoice) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isConnectingVoice
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isConnectingVoice
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                  : const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isConnectingVoice)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF59E0B),
                                  ),
                                )
                              else
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                isConnectingVoice ? 'Conectando ao LiveKit...' : 'Conectado',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isConnectingVoice ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Transmitir Tela Button
                if (isMobile)
                  IconButton(
                    onPressed: onToggleTransmission,
                    icon: Icon(
                      isTransmitting
                          ? LucideIcons.screenShareOff
                          : LucideIcons.screenShare,
                      size: 18,
                      color: isTransmitting
                          ? const Color(0xFFEF4444)
                          : accentColor,
                    ),
                    tooltip: isTransmitting
                        ? 'Parar Transmissão'
                        : 'Transmitir Tela',
                  )
                else
                  ElevatedButton.icon(
                    onPressed: onToggleTransmission,
                    icon: Icon(
                      isTransmitting
                          ? LucideIcons.screenShareOff
                          : LucideIcons.screenShare,
                      size: 14,
                    ),
                    label: Text(
                      isTransmitting ? 'Parar Live' : 'Transmitir',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTransmitting
                          ? const Color(0xFFEF4444)
                          : accentColor,
                      foregroundColor: isTransmitting
                          ? Colors.white
                          : const Color(0xFF181926),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Entrar na Chamada de Voz
                if (isMobile)
                  IconButton(
                    onPressed: onToggleVoiceChannel,
                    icon: isConnectingVoice
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF59E0B),
                            ),
                          )
                        : Icon(
                            isInVoice ? LucideIcons.phoneOff : LucideIcons.phoneCall,
                            size: 18,
                            color: isInVoice
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                    tooltip: isConnectingVoice
                        ? 'Conectando ao LiveKit...'
                        : (isInVoice ? 'Desconectar' : 'Entrar na Voz'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: onToggleVoiceChannel,
                    icon: isConnectingVoice
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            isInVoice ? LucideIcons.phoneOff : LucideIcons.phoneCall,
                            size: 13,
                          ),
                    label: Text(
                      isConnectingVoice
                          ? 'Conectando...'
                          : (isInVoice ? 'Sair da Voz' : 'Conectar Voz'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnectingVoice
                          ? const Color(0xFFD97706)
                          : (isInVoice
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),

                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isRightSidebarVisible
                          ? LucideIcons.panelRightClose
                          : LucideIcons.panelRightOpen,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    tooltip: isRightSidebarVisible
                        ? 'Ocultar Painel Lateral'
                        : 'Mostrar Painel Lateral',
                    onPressed: onToggleRightSidebar,
                  ),
                ],
              ],
            ),
          ),

          // 1.1 Barra de Participantes em Voz no Canal
          if (_channelVoiceParticipants.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F261B) : const Color(0xFFE6F9EE),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_channelVoiceParticipants.length} em call:',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _channelVoiceParticipants.map((p) {
                          final isMe = clientSessionId != null
                              ? p.sessionId == clientSessionId
                              : p.username == username;
                          final devLabel = p.device == 'mobile'
                              ? ' (Celular)'
                              : p.device == 'desktop'
                                  ? ' (Desktop)'
                                  : '';
                          final pColor = resolveAuthorColor(p.username, isDark);
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B3828)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: pColor.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      getAuthorInitials(p.username),
                                      style: TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
                                        color: pColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${p.username}$devLabel${isMe ? " (Você)" : ""}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                if (p.isDeafened) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message: 'Áudio desativado',
                                    child: Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        LucideIcons.headphones,
                                        size: 10,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ] else if (p.isMuted) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message: 'Microfone mutado',
                                    child: Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        LucideIcons.micOff,
                                        size: 10,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (!isInVoice) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onToggleVoiceChannel,
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.phoneCall,
                                size: 11, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'Entrar',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // 2. Banner de Transmissão Ativa no Canal
          if (activeBroadcaster != null)
            ActiveLiveStreamBanner(
              isDark: isDark,
              broadcaster: activeBroadcaster!,
              onWatchLive: onWatchLive,
            ),

          // 3. Messages List Area
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2030)
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.hash,
                                size: 28,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bem-vindo ao #$activeChannelName!',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Este é o início do canal #$activeChannelName.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Envie uma mensagem abaixo para começar a conversar!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isEditing = editingMessageId == msg.id;
                      final isMine =
                          msg.author == username || msg.author == 'Você';
                        final initials = getAuthorInitials(msg.author);
                        final authorColor = resolveAuthorColor(
                          msg.author,
                          isDark,
                        );

                        if (isMine) {
                          // MY MESSAGE (WhatsApp Style -> Aligned to the Right)
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Action Icons (Edit / Delete) to the left of the sent bubble
                                if (!isEditing)
                                  ChatMessageActions(
                                    isDark: isDark,
                                    onEdit: () => onStartEditing(msg.id),
                                    onDelete: () => onDeleteMessage(msg.id),
                                  ),

                                // WhatsApp Message Bubble
                                WhatsAppChatBubble(
                                  msg: msg,
                                  isMine: true,
                                  isDark: isDark,
                                  isEditing: isEditing,
                                  isMobile: isMobile,
                                  screenWidth: screenWidth,
                                  accentColor: accentColor,
                                  editController: editMessageController,
                                  onCancelEdit: onCancelEditing,
                                  onSaveEdit: onSaveEditing,
                                ),
                                const SizedBox(width: 8),

                                // Sender Avatar on the Right with Initials
                                ChatAvatar(
                                  initials: initials,
                                  color: authorColor,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          );
                        } else {
                          // RECEIVED MESSAGE (From others -> Aligned to the Left)
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Author Avatar on the Left with Initials
                                ChatAvatar(
                                  initials: initials,
                                  color: authorColor,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),

                                // WhatsApp Message Bubble
                                WhatsAppChatBubble(
                                  msg: msg,
                                  isMine: false,
                                  isDark: isDark,
                                  isMobile: isMobile,
                                  screenWidth: screenWidth,
                                  authorColor: authorColor,
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
          ),

          // 4. Message Input Bar
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              6,
              20,
              isMobile
                  ? (MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 8.0
                      : 12.0)
                  : 16.0,
            ),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2030)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E314A)
                      : const Color(0xFFCBD5E1),
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {},
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(9999),
                    child: Icon(
                      LucideIcons.plusCircle,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      focusNode: messageFocusNode,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      cursorColor: accentColor,
                      decoration: InputDecoration(
                        hintText: 'Mensagem em #$activeChannelName',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      onSubmitted: (_) {
                        onSendMessage(channelKey, username);
                        messageFocusNode?.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {},
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(9999),
                    child: Icon(
                      LucideIcons.smile,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      onSendMessage(channelKey, username);
                      messageFocusNode?.requestFocus();
                    },
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(9999),
                    child: Icon(
                      LucideIcons.send,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
