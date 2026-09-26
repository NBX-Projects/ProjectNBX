import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/widgets/components/image_lightbox_dialog.dart';

class ChatTimestampText extends StatelessWidget {
  final DateTime? timestamp;
  final bool isEdited;
  final Color textColor;
  final double fontSize;

  const ChatTimestampText({
    super.key,
    required this.timestamp,
    required this.isEdited,
    required this.textColor,
    this.fontSize = 10.5,
  });

  @override
  Widget build(BuildContext context) {
    if (timestamp == null && !isEdited) return const SizedBox.shrink();

    final localTimestamp = timestamp?.toLocal();

    final timeStr = localTimestamp != null
        ? '${localTimestamp.hour.toString().padLeft(2, '0')}:${localTimestamp.minute.toString().padLeft(2, '0')}'
        : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isEdited) ...[
          Text(
            'editada ',
            style: GoogleFonts.inter(
              fontSize: fontSize * 0.95,
              fontStyle: FontStyle.italic,
              color: textColor,
            ),
          ),
        ],
        if (timeStr.isNotEmpty)
          Text(
            timeStr,
            style: GoogleFonts.inter(fontSize: fontSize, color: textColor),
          ),
      ],
    );
  }
}

class ChatMessageActions extends StatelessWidget {
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChatMessageActions({
    super.key,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Editar mensagem',
          child: InkWell(
            onTap: onEdit,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: AppRadius.borderXs,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                LucideIcons.pencil,
                size: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Tooltip(
          message: 'Excluir mensagem',
          child: InkWell(
            onTap: onDelete,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: AppRadius.borderXs,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                LucideIcons.trash2,
                size: 13,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class WhatsAppChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMine;
  final bool isDark;
  final bool isMobile;
  final double screenWidth;
  final Color accentColor;
  final Color authorColor;
  final bool isEditing;
  final TextEditingController? editController;
  final VoidCallback? onCancelEdit;
  final void Function(String messageId)? onSaveEdit;

  const WhatsAppChatBubble({
    super.key,
    required this.msg,
    required this.isMine,
    required this.isDark,
    required this.isMobile,
    required this.screenWidth,
    this.accentColor = const Color(0xFFF5CBA7),
    this.authorColor = const Color(0xFF38BDF8),
    this.isEditing = false,
    this.editController,
    this.onCancelEdit,
    this.onSaveEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine
        ? (isDark ? const Color(0xFF16382B) : const Color(0xFFD9FDD3))
        : (isDark ? const Color(0xFF1E2030) : const Color(0xFFFFFFFF));

    final borderColor = isMine
        ? (isDark
              ? const Color(0xFF265742).withValues(alpha: 0.7)
              : const Color(0xFFB7E4AF))
        : (isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0));

    final borderRadius = isMine
        ? const BorderRadius.only(
            topLeft: AppRadius.radiusLg,
            topRight: AppRadius.radiusLg,
            bottomLeft: AppRadius.radiusLg,
            bottomRight: AppRadius.radiusXs,
          )
        : const BorderRadius.only(
            topLeft: AppRadius.radiusXs,
            topRight: AppRadius.radiusLg,
            bottomLeft: AppRadius.radiusLg,
            bottomRight: AppRadius.radiusLg,
          );

    final timestampColor = isMine
        ? (isDark ? const Color(0xFFA7D5C0) : const Color(0xFF4B775C))
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    final textColor = isMine
        ? (isDark
              ? Colors.white.withValues(alpha: 0.95)
              : const Color(0xFF0F172A))
        : (isDark
              ? Colors.white.withValues(alpha: 0.92)
              : const Color(0xFF1E293B));

    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth * 0.78 : 520,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.22 : (isMine ? 0.05 : 0.04),
              ),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: isEditing && editController != null
            ? _buildEditingForm()
            : _buildMessageContent(context, textColor, timestampColor),
      ),
    );
  }

  Widget _buildEditingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141520) : const Color(0xFFF1F5F9),
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: accentColor, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: editController,
            autofocus: true,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) {
              if (onSaveEdit != null) onSaveEdit!(msg.id);
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (onCancelEdit != null)
              TextButton(
                onPressed: onCancelEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'cancelar',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            if (onSaveEdit != null)
              ElevatedButton(
                onPressed: () => onSaveEdit!(msg.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: accentColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderSm,
                  ),
                ),
                child: Text(
                  'Salvar',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    Color textColor,
    Color timestampColor,
  ) {
    final hasMedia = msg.mediaUrl != null && msg.mediaUrl!.trim().isNotEmpty;
    final hasText = msg.content.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMine) ...[
          Text(
            msg.author,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: authorColor,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (hasMedia) ...[
          GestureDetector(
            key: ValueKey('chat_bubble_media_${msg.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ImageLightboxDialog.show(
                context,
                imageUrl: msg.mediaUrl!,
                caption: hasText ? msg.content : null,
                isDark: isDark,
              );
            },
            child: ClipRRect(
              borderRadius: AppRadius.borderMd,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 180,
                  minHeight: 140,
                  maxWidth: isMobile ? screenWidth * 0.68 : 340,
                  maxHeight: 260,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141520)
                      : const Color(0xFFF1F5F9),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Image.network(
                  msg.mediaUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      width: 220,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      color: isDark
                          ? const Color(0xFF1E2030)
                          : const Color(0xFFE2E8F0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.imageOff,
                            size: 24,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Erro ao carregar imagem',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (hasText) const SizedBox(height: 6),
        ],
        if (hasText)
          Text(
            msg.content,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: textColor,
              height: 1.35,
            ),
          ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ChatTimestampText(
              timestamp: msg.timestamp,
              isEdited: msg.isEdited,
              textColor: timestampColor,
            ),
          ],
        ),
      ],
    );
  }
}
