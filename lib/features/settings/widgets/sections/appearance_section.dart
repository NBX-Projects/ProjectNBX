import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/app_language.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/localization/locale_controller.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/core/theme/theme_controller.dart';
import 'package:justtalking/features/settings/widgets/section_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppearanceSection extends ConsumerWidget {
  final bool isDark;
  final AppStrings strings;
  final bool isMobile;

  const AppearanceSection({
    super.key,
    required this.isDark,
    required this.strings,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(localeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: strings.appearanceAndLanguage,
          description: strings.appearanceDescription,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        Text(
          strings.themeSelector,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        if (isMobile)
          Column(
            children: [
              _buildThemeOptionCard(
                title: strings.darkThemeTitle,
                subtitle: strings.darkThemeSubtitle,
                isSelected: isDark,
                icon: LucideIcons.moon,
                previewBg: const Color(0xFF181926),
                accentColor: const Color(0xFFF5CBA7),
                isDark: isDark,
                onTap: () {
                  if (!isDark) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildThemeOptionCard(
                title: strings.lightThemeTitle,
                subtitle: strings.lightThemeSubtitle,
                isSelected: !isDark,
                icon: LucideIcons.sun,
                previewBg: const Color(0xFFFAF9F6),
                accentColor: const Color(0xFF2D6A4F),
                isDark: isDark,
                onTap: () {
                  if (isDark) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  }
                },
              ),
            ],
          )
        else
          Row(
            children: [
              // Dark Mode Option (Pastel Tech)
              Expanded(
                child: _buildThemeOptionCard(
                  title: strings.darkThemeTitle,
                  subtitle: strings.darkThemeSubtitle,
                  isSelected: isDark,
                  icon: LucideIcons.moon,
                  previewBg: const Color(0xFF181926),
                  accentColor: const Color(0xFFF5CBA7),
                  isDark: isDark,
                  onTap: () {
                    if (!isDark) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Light Mode Option (Forest Slate)
              Expanded(
                child: _buildThemeOptionCard(
                  title: strings.lightThemeTitle,
                  subtitle: strings.lightThemeSubtitle,
                  isSelected: !isDark,
                  icon: LucideIcons.sun,
                  previewBg: const Color(0xFFFAF9F6),
                  accentColor: const Color(0xFF2D6A4F),
                  isDark: isDark,
                  onTap: () {
                    if (isDark) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    }
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 28),

        // Language Selector
        Text(
          strings.languageSelector,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        if (isMobile)
          Column(
            children: AppLanguage.values.map((lang) {
              final isSelected = currentLang == lang;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(localeProvider.notifier).setLanguage(lang);
                  },
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: AppRadius.borderMd,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            LucideIcons.check,
                            size: 16,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        else
          Row(
            children: AppLanguage.values.map((lang) {
              final isSelected = currentLang == lang;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      ref.read(localeProvider.notifier).setLanguage(lang);
                    },
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: AppRadius.borderMd,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lang.name,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              LucideIcons.check,
                              size: 16,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required Color previewBg,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: Text(
                    'Preview',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected && isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
