import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HubHeader extends StatelessWidget {
  final int totalCommunities;
  final int totalInVoice;
  final VoidCallback? onExplore;
  final VoidCallback? onCreateServer;

  const HubHeader({
    super.key,
    required this.totalCommunities,
    required this.totalInVoice,
    this.onExplore,
    this.onCreateServer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createAction = onCreateServer ?? onExplore;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Título e Subtítulo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Início',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$totalCommunities ${totalCommunities == 1 ? "comunidade" : "comunidades"} · $totalInVoice em chamadas agora',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        if (createAction != null)
          Tooltip(
            message: 'Criar Servidor',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: createAction,
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                                .withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 18,
                    color: isDark ? const Color(0xFF181926) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
