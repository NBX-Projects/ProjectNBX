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
    final activeCalls =
        <({ChannelModel channel, List<VoiceParticipantInfo> participants})>[];

    for (final ch in channels) {
      final participants =
          voiceParticipants[ch.id]?.values.where((p) => p.isInVoice).toList() ??
          [];
      if (participants.isNotEmpty) {
        activeCalls.add((channel: ch, participants: participants));
      }
    }

    if (activeCalls.isEmpty) return const SizedBox.shrink();

    if (activeCalls.length == 1) {
      return _buildCallCard(
        context: context,
        callChannel: activeCalls.first.channel,
        activeCallParticipants: activeCalls.first.participants,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < activeCalls.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildCallCard(
            context: context,
            callChannel: activeCalls[i].channel,
            activeCallParticipants: activeCalls[i].participants,
          ),
        ],
      ],
    );
  }

  Widget _buildCallCard({
    required BuildContext context,
    required ChannelModel callChannel,
    required List<VoiceParticipantInfo> activeCallParticipants,
  }) {
    final isUserInCall = connectedVoiceChannelId == callChannel.id;
    final hasTransmitting = activeCallParticipants.any((p) => p.isTransmitting);

    final accentColor = hasTransmitting
        ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
        : (isDark ? AppColors.darkSage : AppColors.lightSage);

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final actionButton = isUserInCall
        ? OutlinedButton.icon(
            onPressed: () => onOpenChannel(callChannel),
            icon: const Icon(LucideIcons.arrowRight, size: 13),
            label: Text(
              'Abrir Canal',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              side: BorderSide(color: cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          )
        : ElevatedButton.icon(
            onPressed: () => onJoinVoice?.call(callChannel),
            icon: Icon(
              hasTransmitting
                  ? LucideIcons.screenShare
                  : LucideIcons.headphones,
              size: 13,
            ),
            label: Text(
              hasTransmitting ? 'Assistir / Entrar' : 'Conectar Áudio',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary,
              foregroundColor: isDark ? const Color(0xFF181926) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIconBadge(accentColor, hasTransmitting),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetails(
                        context,
                        callChannel,
                        activeCallParticipants,
                        accentColor,
                        hasTransmitting,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            )
          : Row(
              children: [
                _buildIconBadge(accentColor, hasTransmitting),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDetails(
                    context,
                    callChannel,
                    activeCallParticipants,
                    accentColor,
                    hasTransmitting,
                  ),
                ),
                const SizedBox(width: 12),
                actionButton,
              ],
            ),
    );
  }

  Widget _buildIconBadge(Color accentColor, bool hasTransmitting) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.12 : 0.09),
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
      ),
      child: Center(
        child: Icon(
          hasTransmitting ? LucideIcons.screenShare : LucideIcons.radio,
          size: 19,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    ChannelModel callChannel,
    List<VoiceParticipantInfo> activeCallParticipants,
    Color accentColor,
    bool hasTransmitting,
  ) {
    final participantsText = activeCallParticipants
        .map((p) => p.isTransmitting ? '${p.username} (Ao vivo)' : p.username)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              hasTransmitting ? 'TRANSMISSÃO AO VIVO' : 'CHAMADA EM ANDAMENTO',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInput : AppColors.lightCanvas,
                borderRadius: AppRadius.borderXs,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.volume2,
                    size: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    callChannel.name,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          participantsText,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
