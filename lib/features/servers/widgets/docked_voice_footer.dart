import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';

/// Rodapé fixo indicando conexão ativa de áudio no canal
class DockedVoiceFooter extends StatelessWidget {
  final bool isDark;
  final String channelName;
  final String serverName;
  final VoiceState voiceState;
  final VoiceStateNotifier voiceNotifier;
  final VoidCallback onLeaveVoice;

  const DockedVoiceFooter({
    super.key,
    required this.isDark,
    required this.channelName,
    required this.serverName,
    required this.voiceState,
    required this.voiceNotifier,
    required this.onLeaveVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF202234) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.65),
                      blurRadius: 7,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Conectado',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const Spacer(),
              Text(
                'Conexão estável',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF10B981).withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$channelName · $serverName',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Tooltip(
                message: voiceState.isMicMuted
                    ? 'Desmutar Microfone'
                    : 'Mutar Microfone',
                child: InkWell(
                  onTap: () => voiceNotifier.toggleMic(),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: voiceState.isMicMuted
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : (isDark
                              ? const Color(0xFF1E2030)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: isDark
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Icon(
                        voiceState.isMicMuted
                            ? LucideIcons.micOff
                            : LucideIcons.mic,
                        size: 16,
                        color: voiceState.isMicMuted
                            ? const Color(0xFFEF4444)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: voiceState.isDeafened
                    ? 'Ativar Áudio'
                    : 'Desativar Áudio',
                child: InkWell(
                  onTap: () => voiceNotifier.toggleDeafened(),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: voiceState.isDeafened
                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                          : (isDark
                              ? const Color(0xFF1E2030)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: isDark
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.headphones,
                        size: 16,
                        color: voiceState.isDeafened
                            ? const Color(0xFFEF4444)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onLeaveVoice,
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Sair',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
