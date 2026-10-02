import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:justtalking/core/localization/locale_controller.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HubRightPanel extends ConsumerWidget {
  final VoidCallback? onClose;

  const HubRightPanel({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(stringsProvider);

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141520) : Colors.white,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  if (onClose != null)
                    Tooltip(
                      message: 'Recolher painel (Ctrl + B)',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: InkWell(
                          onTap: onClose,
                          mouseCursor: SystemMouseCursors.click,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.panelRightClose,
                              size: 16,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () {},
                  mouseCursor: SystemMouseCursors.click,
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
          ),
        ],
      ),
    );
  }
}
