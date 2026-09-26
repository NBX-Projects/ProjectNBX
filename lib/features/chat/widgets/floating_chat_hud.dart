import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/utils/chat_helpers.dart';
import 'package:projectnbx/features/chat/widgets/components/confirm_delete_dialog.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';

/// Pill/Tag para seleção rápida de canais no HUD flutuante
class ChatTagPill extends StatelessWidget {
  final String label;
  final String? badge;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const ChatTagPill({
    super.key,
    required this.label,
    this.badge,
    this.icon,
    this.iconColor,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: AppRadius.borderSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF23305A) : const Color(0xFF141520),
          borderRadius: AppRadius.borderSm,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF384B7E)
                : const Color(0xFF262838),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: iconColor ?? Colors.white70),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Text(
                badge!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// HUD de Chat Flutuante com Glassmorphism e controles rápidos de voz
class FloatingChatHud extends StatelessWidget {
  final String activeChannelName;
  final String channelKey;
  final String username;
  final List<ChatMessage> messages;
  final List<ChannelModel> channels;
  final ChannelModel? activeChannel;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final FocusNode? messageFocusNode;
  final VoiceState voiceState;
  final VoiceStateNotifier voiceNotifier;
  final VoidCallback onClose;
  final ValueChanged<ChannelModel> onSelectChannel;
  final void Function(String channelKey, String author) onSendMessage;
  final void Function(ChatMessage msg) onStartEditing;
  final void Function(String messageId) onDeleteMessage;
  final VoidCallback onLeaveVoice;

  const FloatingChatHud({
    super.key,
    required this.activeChannelName,
    required this.channelKey,
    required this.username,
    required this.messages,
    required this.channels,
    this.activeChannel,
    required this.messageController,
    required this.scrollController,
    this.messageFocusNode,
    required this.voiceState,
    required this.voiceNotifier,
    required this.onClose,
    required this.onSelectChannel,
    required this.onSendMessage,
    required this.onStartEditing,
    required this.onDeleteMessage,
    required this.onLeaveVoice,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveChannels = channels
        .where(
          (c) => c.type == ChannelType.text || c.type == ChannelType.hybrid,
        )
        .toList();
    final displayChannels =
        effectiveChannels.isNotEmpty ? effectiveChannels : channels;

    return ClipRRect(
      borderRadius: AppRadius.borderLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13141F).withValues(alpha: 0.94),
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: const Color(0xFF2E3048).withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HUD Header (Chat title + minimize button)
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF232538))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chats · #$activeChannelName',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Minimizar Chat',
                      child: InkWell(
                        onTap: onClose,
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: AppRadius.borderXs,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.arrowUpRight,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Channel Tag / Filter Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: displayChannels.map((c) {
                    final isSelected =
                        c.id == activeChannel?.id || c.name == activeChannelName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChatTagPill(
                        label: '# ${c.name}',
                        badge: c.unreadCount > 0 ? '${c.unreadCount}' : null,
                        isSelected: isSelected,
                        onTap: () {
                          if (c.id != activeChannel?.id) {
                            onSelectChannel(c);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 3. Real Message Stream
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.messageSquare,
                                size: 26,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhuma mensagem ainda',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Envie uma mensagem abaixo!',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.25),
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
                          horizontal: 14,
                          vertical: 6,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[messages.length - 1 - index];
                          final isMine =
                              msg.author == username || msg.author == 'Você';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${msg.author}: ',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: resolveAuthorColor(
                                              msg.author,
                                              true,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text: msg.content,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                          ),
                                        ),
                                        if (msg.isEdited)
                                          TextSpan(
                                            text: ' (editada)',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.white38,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMine) ...[
                                  InkWell(
                                    onTap: () => onStartEditing(msg),
                                    mouseCursor: SystemMouseCursors.click,
                                    borderRadius: AppRadius.borderXs,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: Icon(
                                        LucideIcons.pencil,
                                        size: 11,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final confirmed =
                                          await ConfirmDeleteDialog.show(
                                            context,
                                          );
                                      if (confirmed == true) {
                                        onDeleteMessage(msg.id);
                                      }
                                    },
                                    mouseCursor: SystemMouseCursors.click,
                                    borderRadius: AppRadius.borderXs,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: Icon(
                                        LucideIcons.trash2,
                                        size: 11,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // 4. Compact Pill Input Field
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F101A),
                    borderRadius: AppRadius.borderPill,
                    border: Border.all(
                      color: const Color(0xFF2B2D42),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          focusNode: messageFocusNode,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Mensagem em #$activeChannelName',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) {
                            onSendMessage(channelKey, username);
                            messageFocusNode?.requestFocus();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          onSendMessage(channelKey, username);
                          messageFocusNode?.requestFocus();
                        },
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: AppRadius.borderPill,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.send,
                            size: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Quick Voice Control Bar inside HUD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0E16),
                  border: Border(top: BorderSide(color: Color(0xFF1E2030))),
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: voiceState.isMicMuted ? 'Desmutar' : 'Mutar',
                      child: InkWell(
                        onTap: () => voiceNotifier.toggleMic(),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: AppRadius.borderSm,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: voiceState.isMicMuted
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Icon(
                            voiceState.isMicMuted
                                ? LucideIcons.micOff
                                : LucideIcons.mic,
                            size: 15,
                            color: voiceState.isMicMuted
                                ? const Color(0xFFEF4444)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: voiceState.isDeafened
                          ? 'Ativar Áudio'
                          : 'Desativar Áudio',
                      child: InkWell(
                        onTap: () => voiceNotifier.toggleDeafened(),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: AppRadius.borderSm,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: voiceState.isDeafened
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Icon(
                            LucideIcons.headphones,
                            size: 15,
                            color: voiceState.isDeafened
                                ? const Color(0xFFEF4444)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onLeaveVoice,
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: AppRadius.borderSm,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.logOut,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sair',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
