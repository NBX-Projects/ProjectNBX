import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/models/server_workspace_enums.dart';

class ServerTopNav extends StatelessWidget {
  final ServerModel server;
  final bool isDark;
  final ServerViewMode viewMode;
  final ChannelModel? activeChannel;
  final Color accentColor;
  final bool isRightSidebarVisible;
  final VoidCallback onBackToHome;
  final VoidCallback? onGoToHub;
  final VoidCallback onInviteMembers;
  final VoidCallback onToggleRightSidebar;
  final VoidCallback onOpenMobileChannelsSheet;
  final int totalInVoice;
  final bool isTransmitting;
  final bool isInVoice;
  final bool isConnectingVoice;
  final VoidCallback? onToggleTransmission;
  final VoidCallback? onToggleVoiceChannel;

  const ServerTopNav({
    super.key,
    required this.server,
    required this.isDark,
    required this.viewMode,
    this.activeChannel,
    required this.accentColor,
    required this.isRightSidebarVisible,
    required this.onBackToHome,
    this.onGoToHub,
    required this.onInviteMembers,
    required this.onToggleRightSidebar,
    required this.onOpenMobileChannelsSheet,
    this.totalInVoice = 0,
    this.isTransmitting = false,
    this.isInVoice = false,
    this.isConnectingVoice = false,
    this.onToggleTransmission,
    this.onToggleVoiceChannel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            tooltip: viewMode == ServerViewMode.channel
                ? 'Voltar ao Início do Servidor'
                : 'Voltar ao Hub Principal',
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            onPressed: onBackToHome,
          ),

          const SizedBox(width: 4),

          // Server Name & Channel Path
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    server.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: isMobile ? 13.5 : 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (viewMode == ServerViewMode.channel &&
                    activeChannel != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '/',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '# ${activeChannel!.name}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Minimalist Transmit & Voice Channel Controls
          if (viewMode == ServerViewMode.channel &&
              activeChannel != null &&
              onToggleTransmission != null) ...[
            Tooltip(
              message: isTransmitting ? 'Parar Transmissão' : 'Transmitir Tela',
              child: InkWell(
                onTap: onToggleTransmission,
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderSm,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isTransmitting
                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                        : (isDark
                            ? const Color(0xFF1E2030)
                            : const Color(0xFFE2E8F0)),
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isTransmitting
                          ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                  ),
                  child: Icon(
                    isTransmitting
                        ? LucideIcons.screenShareOff
                        : LucideIcons.screenShare,
                    size: 16,
                    color: isTransmitting
                        ? const Color(0xFFEF4444)
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          if (viewMode == ServerViewMode.channel &&
              activeChannel != null &&
              onToggleVoiceChannel != null) ...[
            Tooltip(
              message: isConnectingVoice
                  ? 'Conectando ao LiveKit...'
                  : (isInVoice ? 'Desconectar da Voz' : 'Conectar Voz'),
              child: InkWell(
                onTap: onToggleVoiceChannel,
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderSm,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isConnectingVoice
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : (isInVoice
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFF10B981).withValues(alpha: 0.15)),
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isConnectingVoice
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                          : (isInVoice
                              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                              : const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                  ),
                  child: isConnectingVoice
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF59E0B),
                          ),
                        )
                      : Icon(
                          isInVoice
                              ? LucideIcons.phoneOff
                              : LucideIcons.phoneCall,
                          size: 16,
                          color: isInVoice
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Invite / Add Members Button
          InkWell(
            onTap: onInviteMembers,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: AppRadius.borderSm,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.userPlus,
                    size: 13,
                    color: accentColor,
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Convidar',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          if (isMobile) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    viewMode == ServerViewMode.channel
                        ? LucideIcons.layers
                        : LucideIcons.menu,
                    size: 18,
                    color: totalInVoice > 0
                        ? const Color(0xFF22C55E)
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  tooltip: 'Canais e Membros',
                  onPressed: onOpenMobileChannelsSheet,
                ),
                if (totalInVoice > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: AppRadius.borderPill,
                        border: Border.all(
                          color: isDark ? const Color(0xFF141522) : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        totalInVoice > 9 ? '9+' : '$totalInVoice',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            Tooltip(
              message: isRightSidebarVisible
                  ? 'Recolher painel lateral'
                  : 'Expandir painel lateral',
              child: InkWell(
                onTap: onToggleRightSidebar,
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderSm,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2030)
                        : const Color(0xFFE2E8F0),
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Icon(
                    isRightSidebarVisible
                        ? LucideIcons.panelRightClose
                        : LucideIcons.panelRightOpen,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
