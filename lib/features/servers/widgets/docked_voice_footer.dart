import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/features/settings/screens/settings_screen.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/widgets/quick_audio_device_menu.dart';

/// Rodapé fixo indicando conexão ativa de áudio no canal com menu rápido de dispositivos
class DockedVoiceFooter extends StatefulWidget {
  final bool isDark;
  final String channelName;
  final String serverName;
  final VoiceState voiceState;
  final VoiceStateNotifier voiceNotifier;
  final VoidCallback onLeaveVoice;
  final VoidCallback? onToggleMic;
  final VoidCallback? onToggleDeafened;
  final bool isTransmitting;
  final VoidCallback? onToggleTransmission;

  const DockedVoiceFooter({
    super.key,
    required this.isDark,
    required this.channelName,
    required this.serverName,
    required this.voiceState,
    required this.voiceNotifier,
    required this.onLeaveVoice,
    this.onToggleMic,
    this.onToggleDeafened,
    this.isTransmitting = false,
    this.onToggleTransmission,
  });

  @override
  State<DockedVoiceFooter> createState() => _DockedVoiceFooterState();
}

class _DockedVoiceFooterState extends State<DockedVoiceFooter> {
  final GlobalKey _micKey = GlobalKey();
  final GlobalKey _headphoneKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final effectiveBottom = bottomInset > 0 ? bottomInset + 10.0 : 12.0;
    final isDark = widget.isDark;
    final voiceState = widget.voiceState;
    final voiceNotifier = widget.voiceNotifier;
    final isTransmitting = widget.isTransmitting;

    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, effectiveBottom > 8 ? effectiveBottom : 8),
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
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Conectado',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'RTC Seguro',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.channelName} · ${widget.serverName}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.onToggleTransmission != null) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggleTransmission,
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isTransmitting
                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                        : (isDark
                            ? const Color(0xFF1E2030)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTransmitting
                          ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                          : (isDark
                              ? const Color(0xFF313244)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTransmitting
                            ? LucideIcons.screenShareOff
                            : LucideIcons.screenShare,
                        size: 15,
                        color: isTransmitting
                            ? const Color(0xFFEF4444)
                            : (isDark
                                ? const Color(0xFFCAD3F5)
                                : const Color(0xFF334155)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isTransmitting
                            ? 'Parar Transmissão'
                            : 'Compartilhar Tela',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isTransmitting
                              ? const Color(0xFFEF4444)
                              : (isDark
                                  ? const Color(0xFFCAD3F5)
                                  : const Color(0xFF334155)),
                        ),
                      ),
                      if (isTransmitting) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'AO VIVO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. SPLIT BUTTON DO MICROFONE [ 🎙️ | ⌃ ]
              Container(
                key: _micKey,
                height: 32,
                decoration: BoxDecoration(
                  color: voiceState.isMicMuted
                      ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                      : (isDark
                          ? const Color(0xFF1E2030)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: voiceState.isMicMuted
                        ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                        : (isDark
                            ? const Color(0xFF313244)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: voiceState.isMicMuted
                          ? 'Desmutar Microfone'
                          : 'Mutar Microfone',
                      child: InkWell(
                        onTap: () {
                          voiceNotifier.toggleMic();
                          widget.onToggleMic?.call();
                        },
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 6,
                          ),
                          child: Icon(
                            voiceState.isMicMuted
                                ? LucideIcons.micOff
                                : LucideIcons.mic,
                            size: 15,
                            color: voiceState.isMicMuted
                                ? const Color(0xFFEF4444)
                                : (isDark
                                    ? const Color(0xFFCAD3F5)
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: isDark
                          ? const Color(0xFF313244)
                          : const Color(0xFFCBD5E1),
                    ),
                    Tooltip(
                      message: 'Dispositivo de Entrada',
                      child: InkWell(
                        onTap: () => QuickAudioDeviceMenu.show(
                          context,
                          anchorKey: _micKey,
                          isInput: true,
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 6,
                          ),
                          child: Icon(
                            LucideIcons.chevronUp,
                            size: 11,
                            color: isDark
                                ? const Color(0xFFA5ADCB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. SPLIT BUTTON DO FONE [ 🎧 | ⌄ ]
              Container(
                key: _headphoneKey,
                height: 32,
                decoration: BoxDecoration(
                  color: voiceState.isDeafened
                      ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                      : (isDark
                          ? const Color(0xFF1E2030)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: voiceState.isDeafened
                        ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                        : (isDark
                            ? const Color(0xFF313244)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: voiceState.isDeafened
                          ? 'Ativar Áudio'
                          : 'Desativar Áudio',
                      child: InkWell(
                        onTap: () {
                          voiceNotifier.toggleDeafened();
                          widget.onToggleDeafened?.call();
                        },
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 6,
                          ),
                          child: Icon(
                            LucideIcons.headphones,
                            size: 15,
                            color: voiceState.isDeafened
                                ? const Color(0xFFEF4444)
                                : (isDark
                                    ? const Color(0xFFCAD3F5)
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: isDark
                          ? const Color(0xFF313244)
                          : const Color(0xFFCBD5E1),
                    ),
                    Tooltip(
                      message: 'Dispositivo de Saída',
                      child: InkWell(
                        onTap: () => QuickAudioDeviceMenu.show(
                          context,
                          anchorKey: _headphoneKey,
                          isInput: false,
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 6,
                          ),
                          child: Icon(
                            LucideIcons.chevronUp,
                            size: 11,
                            color: isDark
                                ? const Color(0xFFA5ADCB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. BOTÃO DE CONFIGURAÇÕES RÁPIDAS DE VOZ [ ⚙️ ]
              Tooltip(
                message: 'Configurações de Voz',
                child: InkWell(
                  onTap: () =>
                      SettingsScreen.show(context, initialSection: 'voice'),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2030)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF313244)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.settings,
                        size: 15,
                        color: isDark
                            ? const Color(0xFFA5ADCB)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. BOTÃO DESCONECTAR [ 📞 ]
              Tooltip(
                message: 'Desconectar da Voz',
                child: InkWell(
                  onTap: widget.onLeaveVoice,
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.phoneOff,
                        size: 15,
                        color: Color(0xFFEF4444),
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
