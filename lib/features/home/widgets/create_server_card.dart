import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';

class CreateServerCard extends StatefulWidget {
  final VoidCallback? onCreated;

  const CreateServerCard({
    super.key,
    this.onCreated,
  });

  @override
  State<CreateServerCard> createState() => _CreateServerCardState();
}

class _CreateServerCardState extends State<CreateServerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () {
          CreateServerDialog.show(context);
        },
        mouseCursor: SystemMouseCursors.click,
        borderRadius: AppRadius.borderLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: _isHovered
                  ? (isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: (isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary)
                          .withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Banner / Thumbnail in same proportion
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.topLg,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E2030),
                            const Color(0xFF282A36),
                            const Color(0xFF313244),
                          ]
                        : [
                            const Color(0xFFE2E8F0),
                            const Color(0xFFEDF2F7),
                            const Color(0xFFF8FAFC),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Watermark background icon
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        LucideIcons.plus,
                        size: 80,
                        color: (isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary)
                            .withValues(alpha: 0.08),
                      ),
                    ),

                    // Top Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: 0.15),
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(
                            color: (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'NOVO SERVIDOR',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                          ),
                        ),
                      ),
                    ),

                    // Center Plus Icon
                    Center(
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: _isHovered ? 0.25 : 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          size: 22,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Card Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Servidor',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adicione seu espaço para voz e chat',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Action Pill at Bottom
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary)
                            .withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plusCircle,
                            size: 13,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Clique para Criar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
