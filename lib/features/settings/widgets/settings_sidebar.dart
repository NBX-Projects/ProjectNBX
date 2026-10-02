import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsSidebar extends ConsumerWidget {
  final String selectedSection;
  final ValueChanged<String> onSelectSection;
  final bool isDark;
  final AppStrings strings;
  final bool isMobile;
  final bool supportsHotkeys;

  const SettingsSidebar({
    super.key,
    required this.selectedSection,
    required this.onSelectSection,
    required this.isDark,
    required this.strings,
    this.isMobile = false,
    this.supportsHotkeys = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarCategory(strings.userCategory),
        _buildSidebarItem(
          id: 'account',
          title: strings.myAccount,
          icon: LucideIcons.user,
        ),
        _buildSidebarItem(
          id: 'appearance',
          title: strings.appearanceAndLanguage,
          icon: LucideIcons.palette,
        ),

        const SizedBox(height: 16),
        _buildSidebarCategory('ÁUDIO & CONTROLES'),
        _buildSidebarItem(
          id: 'voice',
          title: strings.voiceAndVideo,
          icon: LucideIcons.mic,
        ),
        if (supportsHotkeys)
          _buildSidebarItem(
            id: 'hotkeys',
            title: strings.hotkeysAndPTT,
            icon: LucideIcons.keyboard,
          ),

        const SizedBox(height: 16),
        _buildSidebarCategory('SISTEMA'),
        _buildSidebarItem(
          id: 'system',
          title: strings.systemStatusTitle,
          icon: LucideIcons.activity,
        ),

        if (isMobile) const SizedBox(height: 28) else const Spacer(),

        // Logout Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            mouseCursor: SystemMouseCursors.click,
            borderRadius: isMobile ? AppRadius.borderMd : AppRadius.borderSm,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 12,
                vertical: isMobile ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                    .withValues(alpha: 0.08),
                borderRadius: isMobile ? AppRadius.borderMd : AppRadius.borderSm,
                border: Border.all(
                  color: (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.logOut,
                    size: isMobile ? 18 : 16,
                    color: isDark ? AppColors.darkDanger : AppColors.lightDanger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.logOut,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 13.5 : 12.5,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.darkDanger : AppColors.lightDanger,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      width: isMobile ? double.infinity : 240,
      color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 16,
        vertical: isMobile ? 16 : 16,
      ),
      child: content,
    );
  }

  Widget _buildSidebarCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = selectedSection == id;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 2),
      child: InkWell(
        onTap: () => onSelectSection(id),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: isMobile ? AppRadius.borderMd : AppRadius.borderSm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 12,
            vertical: isMobile ? 12 : 9,
          ),
          decoration: BoxDecoration(
            color: isMobile
                ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                : (isSelected
                      ? (isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated)
                      : Colors.transparent),
            borderRadius: isMobile ? AppRadius.borderMd : AppRadius.borderSm,
            border: Border.all(
              color: isMobile
                  ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  : (isSelected
                        ? (isDark
                              ? AppColors.darkBorderFocus
                              : AppColors.lightBorderFocus)
                        : Colors.transparent),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 0),
                decoration: isMobile
                    ? BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                                .withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderSm,
                      )
                    : null,
                child: Icon(
                  icon,
                  size: isMobile ? 18 : 16,
                  color: isMobile
                      ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                      : (isSelected
                            ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13.5 : 12.5,
                    fontWeight: isMobile
                        ? FontWeight.w600
                        : (isSelected ? FontWeight.w600 : FontWeight.w500),
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (isMobile)
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color:
                      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsCloseButton extends StatelessWidget {
  final bool isDark;

  const SettingsCloseButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Fechar (Esc)',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: AppRadius.borderPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ESC',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
