import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/theme/app_colors.dart';

class HubRightPanel extends ConsumerWidget {
  const HubRightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(stringsProvider);

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141520) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(
              left: 14,
              right: 14,
              top: 16,
              bottom: 48,
            ),
            children: [
              Text(
                strings.recentActivity,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.noNotificationsTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.noNotificationsSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),

          // Botão de Ajuda (?) flutuante no canto inferior direito
          Positioned(
            bottom: 12,
            right: 12,
            child: Tooltip(
              message: 'Central de Ajuda e Documentação',
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF282A36)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.helpCircle,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
