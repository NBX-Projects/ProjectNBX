import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/home/widgets/topbar/user_status_chip.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/widgets/quick_audio_device_menu.dart';
import 'package:window_manager/window_manager.dart';

class HubTopBar extends StatelessWidget {
  final UserModel? user;
  final bool isDark;
  final int totalInVoice;
  final VoiceState voiceState;
  final VoiceStateNotifier voiceNotifier;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenSearch;
  final GlobalKey topMicKey;
  final GlobalKey topHeadphonesKey;

  const HubTopBar({
    super.key,
    required this.user,
    required this.isDark,
    required this.totalInVoice,
    required this.voiceState,
    required this.voiceNotifier,
    required this.onToggleTheme,
    required this.onOpenSearch,
    required this.topMicKey,
    required this.topHeadphonesKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktopPlatform =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    final content = Container(
      width: double.infinity,
      height: 56,
      padding: EdgeInsets.only(
        left: 0,
        right: isDesktopPlatform ? 0 : 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141520) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Marca NBX PROJECT e Barra de Busca
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone Brand NBX (centralizado sobre a largura de 68px da rail)
                SizedBox(
                  width: 68,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4282),
                        borderRadius: AppRadius.borderSm,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B4282).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.zap,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'NBX PROJECT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 16),

                // Campo de Busca com Atalho ctrl + K
                if (!isMobile) ...[
                  Flexible(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: onOpenSearch,
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: AppRadius.borderMd,
                        child: Container(
                          height: 36,
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2030) : const Color(0xFFF1F5F9),
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.search,
                                size: 14,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Buscar servidores, canais, membros...',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF141520) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Text(
                                  'ctrl + K',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Badge "🟢 34 em chamadas"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalInVoice em chamadas',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Ações à Direita: Áudio, AFK, Tema, Usuário e Controles de Janela
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Microfone
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onSecondaryTap: () => QuickAudioDeviceMenu.show(
                    context,
                    anchorKey: topMicKey,
                    isInput: true,
                  ),
                  child: _TopBarIconButton(
                    key: topMicKey,
                    icon: voiceState.isMicMuted ? LucideIcons.micOff : LucideIcons.mic,
                    tooltip: voiceState.isMicMuted ? 'Desmutar Microfone' : 'Mutar Microfone',
                    isActive: voiceState.isMicMuted,
                    isDark: isDark,
                    onPressed: () => voiceNotifier.toggleMic(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Fone de Ouvido
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onSecondaryTap: () => QuickAudioDeviceMenu.show(
                    context,
                    anchorKey: topHeadphonesKey,
                    isInput: false,
                  ),
                  child: _TopBarIconButton(
                    key: topHeadphonesKey,
                    icon: LucideIcons.headphones,
                    tooltip: voiceState.isDeafened ? 'Ativar Áudio' : 'Desativar Áudio',
                    isActive: voiceState.isDeafened,
                    isDark: isDark,
                    onPressed: () => voiceNotifier.toggleDeafened(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botão AFK (mantendo o mesmo padrão dos outros botões de ícone)
              _TopBarIconButton(
                icon: LucideIcons.clock,
                tooltip: 'AFK',
                isDark: isDark,
                onPressed: () {},
              ),

              const SizedBox(width: 8),

              // Alternador de Tema
              _TopBarIconButton(
                icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
                color: isDark ? const Color(0xFFF5CBA7) : const Color(0xFF2D6A4F),
                isDark: isDark,
                onPressed: onToggleTheme,
              ),

              const SizedBox(width: 8),

              // Chip do Usuário
              UserStatusChip(user: user, isDark: isDark),

              // Controles de Janela do Windows
              if (isDesktopPlatform) ...[
                const SizedBox(width: 10),
                Container(
                  height: 24,
                  width: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(width: 4),
                const WindowControls(height: 56, buttonWidth: 46),
              ],
            ],
          ),
        ],
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isDesktopPlatform ? DragToMoveArea(child: content) : content,
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final bool isActive;
  final Color? color;
  final VoidCallback onPressed;

  const _TopBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? (isActive
        ? Colors.redAccent
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: isActive
              ? Colors.redAccent.withValues(alpha: 0.16)
              : (isDark ? const Color(0xFF2B2F36) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(child: Icon(icon, size: 16, color: foreground)),
            ),
          ),
        ),
      ),
    );
  }
}
