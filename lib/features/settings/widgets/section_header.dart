import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String description;
  final bool isDark;

  const SectionHeader({
    super.key,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
