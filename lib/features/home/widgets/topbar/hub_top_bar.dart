import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/locale_controller.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/core/widgets/window_controls.dart';
import 'package:justtalking/features/auth/models/user_model.dart';
import 'package:justtalking/features/home/widgets/topbar/user_status_chip.dart';
import 'package:justtalking/features/voice/controllers/voice_state_controller.dart';
import 'package:justtalking/features/voice/widgets/quick_audio_device_menu.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class HubTopBar extends ConsumerWidget {
  final UserModel? user;
  final bool isDark;
  final int totalInVoice;
  final VoiceState voiceState;
  final VoiceStateNotifier voiceNotifier;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onOpenSearch;
  final GlobalKey topMicKey;
  final GlobalKey topHeadphonesKey;
  final bool isRightSidebarVisible;
  final VoidCallback? onToggleRightSidebar;

  const HubTopBar({
    super.key,
    required this.user,
    required this.isDark,
    required this.totalInVoice,
    required this.voiceState,
    required this.voiceNotifier,
    this.onToggleTheme,
    this.onOpenSearch,
    required this.topMicKey,
    required this.topHeadphonesKey,
    this.isRightSidebarVisible = false,
    this.onToggleRightSidebar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isDesktopPlatform =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    final actions = [
      _TopBarAction(
        key: topMicKey,
        icon: voiceState.isMicMuted ? LucideIcons.micOff : LucideIcons.mic,
        tooltip: voiceState.isMicMuted
            ? 'Desmutar Microfone'
            : 'Mutar Microfone',
        isActive: voiceState.isMicMuted,
        onPressed: voiceNotifier.toggleMic,
        onSecondaryTap: () => QuickAudioDeviceMenu.show(
          context,
          anchorKey: topMicKey,
          isInput: true,
        ),
      ),
      _TopBarAction(
        key: topHeadphonesKey,
        icon: LucideIcons.headphones,
        tooltip: voiceState.isDeafened ? 'Ativar Áudio' : 'Desativar Áudio',
        isActive: voiceState.isDeafened,
        onPressed: voiceNotifier.toggleDeafened,
        onSecondaryTap: () => QuickAudioDeviceMenu.show(
          context,
          anchorKey: topHeadphonesKey,
          isInput: false,
        ),
      ),
      // TODO: IMPLEMENTAÇÃO FUTURA - Ação de AFK
      // _TopBarAction(
      //   icon: LucideIcons.clock,
      //   tooltip: 'AFK',
      //   onPressed: () {},
      // ),
      // TODO: IMPLEMENTAÇÃO FUTURA - left sidebar
      // if (onToggleRightSidebar != null && !isRightSidebarVisible)
      //   _TopBarAction(
      //     icon: LucideIcons.panelRightOpen,
      //     tooltip: 'Abrir Atividade Recente (Ctrl + B)',
      //     onPressed: onToggleRightSidebar!,
      //   ),
    ];

    final content = Container(
      width: double.infinity,
      height: 56,
      padding: EdgeInsets.only(left: 0, right: isDesktopPlatform ? 0 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141520) : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 68,
                  child: Center(
                    child: SvgPicture.asset(
                      isDark
                          ? 'assets/brand/nbx-projects-symbol-dark.svg'
                          : 'assets/brand/nbx-projects-symbol.svg',
                      width: 32,
                      height: 32,
                      semanticsLabel: 'Símbolo do Just Talking',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  strings.appTitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),

                // TODO: IMPLEMENTAÇÃO FUTURA - Campo de busca rápida e status de voz extraídos
                // para o componente [HubTopBarSearchSection], temporariamente oculto da barra superior.
                // if (!isMobile && onOpenSearch != null)
                //   HubTopBarSearchSection(
                //     isDark: isDark,
                //     onOpenSearch: onOpenSearch!,
                //     totalInVoice: totalInVoice,
                //   ),
              ],
            ),
          ),

          // 2. Ações à Direita: Áudio, AFK, Atividade, Usuário e Controles de Janela
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions) ...[
                _TopBarIconButton(
                  key: action.key,
                  action: action,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
              ],

              // Chip do Usuário
              UserStatusChip(
                user: user,
                isDark: isDark,
                onToggleTheme: onToggleTheme,
              ),

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

class _TopBarAction {
  final Key? key;
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;
  final VoidCallback? onSecondaryTap;

  const _TopBarAction({
    this.key,
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    required this.onPressed,
    this.onSecondaryTap,
  });
}

class _TopBarIconButton extends StatelessWidget {
  final _TopBarAction action;
  final bool isDark;

  const _TopBarIconButton({
    super.key,
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = action.isActive
        ? Colors.redAccent
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Tooltip(
      message: action.tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: action.onPressed,
          onSecondaryTap: action.onSecondaryTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Icon(action.icon, size: 18, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// Componente para o campo de busca rápida (Ctrl + K) e indicador de chamadas ativas.
/// TODO: IMPLEMENTAÇÃO FUTURA - Pronto para reativação quando a busca global for reintroduzida no topo.
class HubTopBarSearchSection extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onOpenSearch;
  final int totalInVoice;

  const HubTopBarSearchSection({
    super.key,
    required this.isDark,
    required this.onOpenSearch,
    this.totalInVoice = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                    color: isDark
                        ? const Color(0xFF1E2030)
                        : const Color(0xFFF1F5F9),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.searchPlaceholder,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141520)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          'ctrl + K',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (totalInVoice > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: AppRadius.borderMd,
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
                    '$totalInVoice ${strings.inCallsBadge}',
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
    );
  }
}
