import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';
import 'package:projectnbx/features/voice/widgets/screen_share_dialog.dart';
import 'package:projectnbx/features/voice/widgets/screen_share_view.dart';
import 'package:projectnbx/features/voice/widgets/viewports/stream_preview_viewports.dart';

/// Banner compacto informando que um participante está transmitindo ao vivo
class ActiveLiveStreamBanner extends StatelessWidget {
  final bool isDark;
  final VoiceParticipantInfo broadcaster;
  final VoidCallback onWatchLive;

  const ActiveLiveStreamBanner({
    super.key,
    required this.isDark,
    required this.broadcaster,
    required this.onWatchLive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1428) : const Color(0xFFFAF5FF),
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: const Color(0xFFA855F7).withValues(alpha: isDark ? 0.6 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.18),
              borderRadius: AppRadius.borderPill,
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'AO VIVO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${broadcaster.username} está transmitindo',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  broadcaster.streamTitle ?? 'Tela Principal',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onWatchLive,
            icon: const Icon(LucideIcons.play, size: 13),
            label: const Text(
              'Assistir Live',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              shape: AppRadius.shapePill,
            ),
          ),
        ],
      ),
    );
  }
}

/// Player de transmissão imersivo com canvas em tempo real e HUD superior
class ImmersiveStreamPlayer extends StatelessWidget {
  final bool isDark;
  final String username;
  final VoiceParticipantInfo? remoteParticipant;
  final ScreenShareConfig? activeScreenShareConfig;
  final LocalVideoTrack? localScreenShareTrack;
  final rtc.MediaStream? webRTCStream;
  final Color accentColor;
  final double streamVolume;
  final VoidCallback? onBackToChat;

  const ImmersiveStreamPlayer({
    super.key,
    required this.isDark,
    required this.username,
    this.remoteParticipant,
    this.activeScreenShareConfig,
    this.localScreenShareTrack,
    this.webRTCStream,
    this.accentColor = const Color(0xFFF5CBA7),
    this.streamVolume = 0.75,
    this.onBackToChat,
  });

  @override
  Widget build(BuildContext context) {
    final isRemote = remoteParticipant != null;
    final title = isRemote
        ? (remoteParticipant!.streamTitle ?? 'Transmissão')
        : (activeScreenShareConfig?.title ?? 'Tela Principal');
    final resolution = activeScreenShareConfig?.resolution ?? '1080p';
    final fps = activeScreenShareConfig?.fps ?? 60;
    final previewType = isRemote
        ? (remoteParticipant!.previewType ?? 'nbx')
        : (activeScreenShareConfig?.previewType ?? 'nbx');
    final shareAudio = isRemote
        ? true
        : (activeScreenShareConfig?.shareAudio ?? true);
    final thumb = isRemote
        ? remoteParticipant!.thumbnail
        : activeScreenShareConfig?.thumbnail;

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF090A10)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Screen / Window Video Feed Canvas
          Positioned.fill(
            child: _buildLiveStreamContent(
              previewType: previewType,
              title: title,
              remoteThumbnail: thumb,
            ),
          ),

          // 2. Top HUD Overlay (Live Badge, App Name, Telemetry, Audio Meter)
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 740;
                final isVeryCompact = constraints.maxWidth < 560;

                return Row(
                  children: [
                    // Live Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: AppRadius.borderPill,
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AO VIVO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Active Window / App Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: AppRadius.borderPill,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.screenShare,
                              size: 13,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!isVeryCompact) ...[
                      const SizedBox(width: 8),
                      // SFU Realtime Telemetry Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: AppRadius.borderPill,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          isCompact
                              ? '$resolution $fps FPS'
                              : '$resolution • $fps FPS • 6.8 Mbps',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Live Audio Visualizer Equalizer
                    if (shareAudio && streamVolume > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.15),
                          borderRadius: AppRadius.borderPill,
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.volume2,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 5),
                              Text(
                                'ÁUDIO',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                            const SizedBox(width: 5),
                            _buildMiniAudioEqualizer(),
                          ],
                        ),
                      ),

                    if (isRemote && onBackToChat != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onBackToChat,
                        borderRadius: AppRadius.borderPill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.arrowLeft,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Voltar ao Chat',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // 3. Subtle Vignette & Gradient Edges
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.15, 0.85, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStreamContent({
    required String previewType,
    required String title,
    String? remoteThumbnail,
  }) {
    if (webRTCStream != null) {
      return Container(
        color: const Color(0xFF090A10),
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ScreenShareView(
              stream: webRTCStream!,
              isLocal: localScreenShareTrack != null,
              broadcasterName: title,
              onClose: onBackToChat,
            ),
          ),
        ),
      );
    }

    if (localScreenShareTrack != null && remoteThumbnail == null) {
      return Container(
        color: const Color(0xFF090A10),
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoTrackRenderer(
              localScreenShareTrack!,
              fit: VideoViewFit.contain,
            ),
          ),
        ),
      );
    }

    final thumbB64 = remoteThumbnail ?? activeScreenShareConfig?.thumbnail;
    if (thumbB64 != null && thumbB64.isNotEmpty) {
      try {
        final bytes = base64Decode(thumbB64);
        return Container(
          color: const Color(0xFF090A10),
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
        );
      } catch (_) {}
    }

    return StreamPreviewViewportSelector(
      previewType: previewType,
      title: title,
      accentColor: accentColor,
    );
  }

  Widget _buildMiniAudioEqualizer() {
    return Row(
      children: List.generate(4, (i) {
        final heights = [6, 12, 8, 14];
        return Container(
          width: 2.5,
          height: heights[i].toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 1.2),
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            borderRadius: AppRadius.borderXs,
          ),
        );
      }),
    );
  }
}
