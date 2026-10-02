import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/servers/models/channel_model.dart';
import 'package:justtalking/features/voice/models/voice_participant_info.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ServerActiveCallBanner extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  final List<ChannelModel> channels;
  final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants;
  final String? connectedVoiceChannelId;
  final ValueChanged<ChannelModel> onOpenChannel;
  final ValueChanged<ChannelModel>? onJoinVoice;

  const ServerActiveCallBanner({
    super.key,
    this.isMobile = false,
    required this.isDark,
    required this.channels,
    required this.voiceParticipants,
    this.connectedVoiceChannelId,
    required this.onOpenChannel,
    this.onJoinVoice,
  });

  @override
  Widget build(BuildContext context) {
    ChannelModel? callChannel;
    List<VoiceParticipantInfo> activeCallParticipants = [];

    for (final ch in channels) {
      final participants =
          voiceParticipants[ch.id]?.values.where((p) => p.isInVoice).toList() ??
          [];
      if (participants.isNotEmpty) {
        callChannel = ch;
        activeCallParticipants = participants;
        break;
      }
    }

    if (callChannel == null) return const SizedBox.shrink();

    final isUserInCall = connectedVoiceChannelId == callChannel.id;

    final hasTransmitting = activeCallParticipants.any((p) => p.isTransmitting);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10281C) : const Color(0xFFECFDF5),
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: hasTransmitting
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : const Color(0xFF22C55E).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasTransmitting ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(
              hasTransmitting ? LucideIcons.screenShare : LucideIcons.phoneCall,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasTransmitting ? 'TRANSMISSÃO AO VIVO' : 'CHAMADA AO VIVO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: hasTransmitting ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: (hasTransmitting ? const Color(0xFFEF4444) : const Color(0xFF22C55E)).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${callChannel.name}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: hasTransmitting ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  activeCallParticipants
                      .map((p) => p.isTransmitting ? '${p.username} 🔴' : p.username)
                      .join(', '),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {
              if (isUserInCall) {
                onOpenChannel(callChannel!);
              } else {
                onJoinVoice?.call(callChannel!);
              }
            },
            icon: Icon(
              isUserInCall ? LucideIcons.arrowRight : LucideIcons.phone,
              size: 13,
            ),
            label: Text(
              isUserInCall ? 'Entrar no Canal' : 'Conectar Áudio',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
