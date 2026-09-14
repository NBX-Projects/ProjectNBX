import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';
import 'package:projectnbx/features/voice/widgets/screen_share_dialog.dart';

/// Barra de controles inferiores do palco de transmissão
class StreamStageBottomBar extends StatelessWidget {
  final bool isDark;
  final String username;
  final VoiceParticipantInfo? remoteParticipant;
  final ScreenShareConfig? activeScreenShareConfig;
  final double streamVolume;
  final ValueChanged<double> onVolumeChanged;
  final bool isChatVisible;
  final VoidCallback onToggleChat;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onStopOrLeave;
  final Color accentColor;

  const StreamStageBottomBar({
    super.key,
    required this.isDark,
    required this.username,
    this.remoteParticipant,
    this.activeScreenShareConfig,
    required this.streamVolume,
    required this.onVolumeChanged,
    required this.isChatVisible,
    required this.onToggleChat,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.onStopOrLeave,
    this.accentColor = const Color(0xFFF5CBA7),
  });

  @override
  Widget build(BuildContext context) {
    final isRemote = remoteParticipant != null;
    final title = isRemote
        ? (remoteParticipant!.streamTitle ?? 'Transmissão de Tela')
        : (activeScreenShareConfig?.title ?? 'Transmissão de Tela');
    final resolution = activeScreenShareConfig?.resolution ?? '1080p';
    final fps = activeScreenShareConfig?.fps ?? 60;
    final shareAudio = isRemote
        ? true
        : (activeScreenShareConfig?.shareAudio ?? true);
    final displayName = isRemote ? remoteParticipant!.username : username;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.94)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 740;
          final isVeryCompact = constraints.maxWidth < 560;

          return Row(
            children: [
              // Live Indicator Badge
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFEF4444),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AO VIVO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '$displayName — $title',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isVeryCompact) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCompact ? '$fps FPS' : '$resolution $fps FPS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Audio Mute/Volume Control
              if (shareAudio) ...[
                IconButton(
                  icon: Icon(
                    streamVolume == 0
                        ? LucideIcons.volumeX
                        : LucideIcons.volume2,
                    size: 16,
                    color: streamVolume > 0
                        ? const Color(0xFF4ADE80)
                        : Colors.white70,
                  ),
                  tooltip: streamVolume == 0 ? 'Ativar Som' : 'Silenciar',
                  onPressed: () {
                    onVolumeChanged(streamVolume == 0 ? 0.75 : 0);
                  },
                ),
                if (!isVeryCompact) ...[
                  SizedBox(
                    width: isCompact ? 50 : 80,
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        trackHeight: 3,
                        activeTrackColor: const Color(0xFF4ADE80),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xFF4ADE80),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: streamVolume,
                        onChanged: onVolumeChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],

              // Chat Visibility HUD Toggle
              IconButton(
                icon: Icon(
                  isChatVisible
                      ? LucideIcons.messageSquare
                      : LucideIcons.messageSquareOff,
                  size: 16,
                  color: isChatVisible ? accentColor : Colors.white70,
                ),
                tooltip:
                    isChatVisible ? 'Ocultar Chat HUD' : 'Mostrar Chat HUD',
                onPressed: onToggleChat,
              ),

              const SizedBox(width: 4),

              // Fullscreen Toggle
              IconButton(
                icon: Icon(
                  isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
                  size: 16,
                  color: Colors.white70,
                ),
                tooltip: 'Tela Cheia',
                onPressed: onToggleFullscreen,
              ),

              const SizedBox(width: 8),

              // Stop Stream or Leave Stream Button
              ElevatedButton.icon(
                onPressed: onStopOrLeave,
                icon: Icon(
                  isRemote ? LucideIcons.logOut : LucideIcons.screenShareOff,
                  size: 14,
                ),
                label: Text(
                  isRemote
                      ? (isCompact ? 'Sair' : 'Sair da Live')
                      : (isCompact ? 'Parar' : 'Parar Transmissão'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
