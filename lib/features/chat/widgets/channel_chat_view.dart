import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
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
  final VoidCallback? onToggleTransmission;
  final VoidCallback? onToggleVoiceChannel;
  final VoidCallback? onToggleRightSidebar;
  final VoidCallback? onWatchLive;
  final void Function(String channelKey, String author) onSendMessage;
  final void Function(String messageId) onStartEditing;
  final VoidCallback onCancelEditing;
  final void Function(String messageId) onSaveEditing;
  final void Function(String messageId) onDeleteMessage;
  final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants;
  final String? clientSessionId;
  final String? connectedVoiceChannelId;

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
    this.isTransmitting = false,
    this.isInVoice = false,
    this.isConnectingVoice = false,
    this.isVoiceConnected = false,
    this.isRightSidebarVisible = false,
    this.accentColor = const Color(0xFFF5CBA7),
    this.activeBroadcaster,
    this.onToggleTransmission,
    this.onToggleVoiceChannel,
    this.onToggleRightSidebar,
    this.onWatchLive,
    required this.onSendMessage,
    required this.onStartEditing,
    required this.onCancelEditing,
    required this.onSaveEditing,
    required this.onDeleteMessage,
    this.voiceParticipants = const {},
    this.clientSessionId,
    this.connectedVoiceChannelId,
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

    final isConnectedToThisChannel =
        isInVoice && connectedVoiceChannelId == channelKey;
    final isConnectedToOtherChannel =
        isInVoice &&
        connectedVoiceChannelId != null &&
        connectedVoiceChannelId != channelKey;

    return Container(
      color: isDark ? const Color(0xFF13141F) : const Color(0xFFFAF9F6),
      child: Column(
        children: [
          // 1. Barra de Participantes em Voz no Canal
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
                              borderRadius: AppRadius.borderPill,
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
                                        borderRadius: AppRadius.borderXs,
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
                                        borderRadius: AppRadius.borderXs,
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
                  if (!isConnectedToThisChannel) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: isConnectedToOtherChannel
                          ? 'Mudar voz para #$activeChannelName'
                          : 'Entrar na chamada de voz',
                      child: InkWell(
                        onTap: onToggleVoiceChannel,
                        borderRadius: AppRadius.borderPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConnectedToOtherChannel
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF22C55E),
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isConnectedToOtherChannel
                                    ? LucideIcons.phoneForwarded
                                    : LucideIcons.phoneCall,
                                size: 11,
                                color: isConnectedToOtherChannel
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isConnectedToOtherChannel
                                    ? 'Mudar para cá'
                                    : 'Entrar',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isConnectedToOtherChannel
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Sair da chamada de voz',
                      child: InkWell(
                        onTap: onToggleVoiceChannel,
                        borderRadius: AppRadius.borderPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.phoneOff,
                                  size: 11, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Text(
                                'Sair',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
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
              onWatchLive: onWatchLive ?? () {},
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
                borderRadius: AppRadius.borderMd,
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
                    borderRadius: AppRadius.borderPill,
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
                    borderRadius: AppRadius.borderPill,
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
                    borderRadius: AppRadius.borderPill,
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
