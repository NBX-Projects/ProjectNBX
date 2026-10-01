import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';

class HubHeader extends StatelessWidget {
  final int totalCommunities;
  final int totalInVoice;
  final VoidCallback onExplore;

  const HubHeader({
    super.key,
    required this.totalCommunities,
    required this.totalInVoice,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Título e Subtítulo
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Início',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$totalCommunities ${totalCommunities == 1 ? "comunidade" : "comunidades"} · $totalInVoice em chamadas agora',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),

        // Botão "+ Explorar" Pill
        ElevatedButton.icon(
          onPressed: onExplore,
          icon: const Icon(LucideIcons.plus, size: 14),
          label: Text(
            'Explorar',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF282A36) : const Color(0xFFE2E8F0),
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
