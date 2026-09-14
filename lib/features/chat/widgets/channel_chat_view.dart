import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/utils/chat_helpers.dart';
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.hash,
                              size: 26,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Bem-vindo a #$activeChannelName!',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Este é o início do canal de texto e transmissão.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF181926)
                                : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF26283D)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          accentColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.hash,
                                        size: 18,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Canal #$activeChannelName',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Criado para mensagens e colaboração em tempo real',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      final msg = messages[index - 1];
                      final isEditing = editingMessageId == msg.id;
                      final isCurrentUser = msg.author == username;
                      final authorColor = resolveAuthorColor(msg.author, isDark);
                      final initials = getAuthorInitials(msg.author);

                      if (isEditing) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E2030)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Editando mensagem',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: onCancelEditing,
                                    child: const Text('Cancelar',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    onPressed: () => onSaveEditing(msg.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: const Color(0xFF181926),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                    ),
                                    child: const Text('Salvar',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: editMessageController,
                                autofocus: true,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => onSaveEditing(msg.id),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChatAvatar(
                              initials: initials,
                              color: authorColor,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        msg.author,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: authorColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (msg.timestamp != null)
                                        Text(
                                          '${msg.timestamp!.hour.toString().padLeft(2, '0')}:${msg.timestamp!.minute.toString().padLeft(2, '0')}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      if (msg.isEdited) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '(editada)',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontStyle: FontStyle.italic,
                                            color: isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      if (isCurrentUser)
                                        PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          iconSize: 14,
                                          icon: Icon(
                                            LucideIcons.moreHorizontal,
                                            size: 14,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black38,
                                          ),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              onStartEditing(msg.id);
                                            } else if (val == 'delete') {
                                              onDeleteMessage(msg.id);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Editar Mensagem',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Excluir Mensagem',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    msg.content,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.92)
                                          : const Color(0xFF1E293B),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
