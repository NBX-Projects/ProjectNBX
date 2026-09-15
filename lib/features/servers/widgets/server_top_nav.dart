import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
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
  final VoidCallback onGoToHub;
  final VoidCallback onInviteMembers;
  final VoidCallback onToggleRightSidebar;
  final VoidCallback onOpenMobileChannelsSheet;
  final int totalInVoice;

  const ServerTopNav({
    super.key,
    required this.server,
    required this.isDark,
    required this.viewMode,
    this.activeChannel,
    required this.accentColor,
    required this.isRightSidebarVisible,
    required this.onBackToHome,
    required this.onGoToHub,
    required this.onInviteMembers,
    required this.onToggleRightSidebar,
    required this.onOpenMobileChannelsSheet,
    this.totalInVoice = 0,
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
          // Back to Hub Button
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            tooltip: 'Voltar ao Hub Principal',
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            onPressed: onBackToHome,
          ),

          if (!isMobile) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onGoToHub,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: viewMode == ServerViewMode.home
                      ? accentColor
                      : (isDark
                          ? const Color(0xFF1E2030)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: viewMode == ServerViewMode.home
                        ? Colors.transparent
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.layoutGrid,
                      size: 13,
                      color: viewMode == ServerViewMode.home
                          ? Colors.black
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hub',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: viewMode == ServerViewMode.home
                            ? Colors.black
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Server Name
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

          const SizedBox(width: 6),

          // Invite / Add Members Button
          InkWell(
            onTap: onInviteMembers,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(9999),
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2030)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
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
