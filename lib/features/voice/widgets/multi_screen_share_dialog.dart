import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/chat/utils/chat_helpers.dart';
import 'package:justtalking/features/voice/models/voice_participant_info.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal para visualização e seleção entre múltiplas transmissões ativas no canal
class MultiScreenShareDialog extends StatelessWidget {
  final bool isDark;
  final String channelName;
  final List<VoiceParticipantInfo> activeBroadcasters;
  final VoiceParticipantInfo? currentlyWatching;
  final ValueChanged<VoiceParticipantInfo> onSelectStream;

  const MultiScreenShareDialog({
    super.key,
    required this.isDark,
    required this.channelName,
    required this.activeBroadcasters,
    this.currentlyWatching,
    required this.onSelectStream,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isDark,
    required String channelName,
    required List<VoiceParticipantInfo> activeBroadcasters,
    VoiceParticipantInfo? currentlyWatching,
    required ValueChanged<VoiceParticipantInfo> onSelectStream,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => MultiScreenShareDialog(
        isDark: isDark,
        channelName: channelName,
        activeBroadcasters: activeBroadcasters,
        currentlyWatching: currentlyWatching,
        onSelectStream: onSelectStream,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF181926) : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: const Icon(
                      LucideIcons.screenShare,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transmissões ao Vivo',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${activeBroadcasters.length} ${activeBroadcasters.length == 1 ? "stream acontecendo" : "streams acontecendo"} em #$channelName',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Lista de Streams Ativas
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeBroadcasters.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final broadcaster = activeBroadcasters[index];
                    final isWatchingThis = currentlyWatching != null &&
                        (currentlyWatching!.userId == broadcaster.userId ||
                            currentlyWatching!.sessionId == broadcaster.sessionId);
                    final authorColor = resolveAuthorColor(broadcaster.username, isDark);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2030) : const Color(0xFFF8FAFC),
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(
                          color: isWatchingThis
                              ? const Color(0xFF9333EA)
                              : (isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0)),
                          width: isWatchingThis ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar do Broadcaster
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: authorColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: authorColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                getAuthorInitials(broadcaster.username),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: authorColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Detalhes da Live
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      broadcaster.username,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                                        borderRadius: AppRadius.borderPill,
                                        border: Border.all(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'AO VIVO',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  broadcaster.streamTitle ?? 'Compartilhamento de Tela',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Botão de Ação
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onSelectStream(broadcaster);
                            },
                            icon: Icon(
                              isWatchingThis ? LucideIcons.eye : LucideIcons.play,
                              size: 13,
                            ),
                            label: Text(
                              isWatchingThis ? 'Assistindo' : 'Assistir',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isWatchingThis
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF9333EA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: AppRadius.shapePill,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Fechar',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
