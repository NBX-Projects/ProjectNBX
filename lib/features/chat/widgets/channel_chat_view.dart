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
  final String? editingMessageId;
  final bool isTransmitting;
  final bool isInVoice;
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
    this.editingMessageId,
    required this.isTransmitting,
    required this.isInVoice,
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
  });

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
                    icon: Icon(
                      isInVoice ? LucideIcons.phoneOff : LucideIcons.phoneCall,
                      size: 18,
                      color: isInVoice
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                    tooltip: isInVoice ? 'Desconectar' : 'Entrar na Voz',
                  )
                else
                  ElevatedButton.icon(
                    onPressed: onToggleVoiceChannel,
                    icon: Icon(
                      isInVoice ? LucideIcons.phoneOff : LucideIcons.phoneCall,
                      size: 13,
                    ),
                    label: Text(
                      isInVoice ? 'Sair da Voz' : 'Conectar Voz',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInVoice
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
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
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
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
          ),

          // 4. Message Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
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
                      onSubmitted: (_) => onSendMessage(channelKey, username),
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
                    onTap: () => onSendMessage(channelKey, username),
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
