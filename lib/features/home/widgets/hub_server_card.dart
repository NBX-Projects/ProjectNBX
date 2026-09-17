import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';

class HubServerCard extends StatefulWidget {
  final ServerModel server;
  final VoidCallback? onTap;

  const HubServerCard({
    super.key,
    required this.server,
    this.onTap,
  });

  @override
  State<HubServerCard> createState() => _HubServerCardState();
}

class _HubServerCardState extends State<HubServerCard> {
  bool _isHovered = false;

  List<Color> _getGradientForServer(ServerModel server) {
    return AppColors.getBannerGradient(server.bannerPreset, server.id);
  }

  String _getCategoryForServer(ServerModel server) {
    if (server.category.isNotEmpty) {
      return server.category.toUpperCase();
    }
    final lower = server.name.toLowerCase();
    if (lower.contains('apex') || lower.contains('game') || lower.contains('jogos')) {
      return 'GAMING';
    }
    if (lower.contains('dev') || lower.contains('code') || lower.contains('tech')) {
      return 'PROGRAMAÇÃO';
    }
    if (lower.contains('mans') || lower.contains('race') || lower.contains('sim')) {
      return 'RACING SIM';
    }
    if (lower.contains('study') || lower.contains('estudo')) {
      return 'ESTUDO';
    }
    if (lower.contains('cs2') || lower.contains('fps') || lower.contains('valorant')) {
      return 'FPS';
    }
    return 'COMUNIDADE';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final server = widget.server;
    final category = _getCategoryForServer(server);
    final gradient = _getGradientForServer(server);
    final accentColor = Color(server.accentColor);

    final voiceChannels = server.channels
        .where((c) => c.type == ChannelType.voice)
        .toList();
    final hasVoice = voiceChannels.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: AppRadius.borderLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: _isHovered
                  ? accentColor
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
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
              // 1. Top Thumbnail / Banner
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.topLg,
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        LucideIcons.gamepad2,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),

                    // Top Category Pill
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Voice Badge (Bottom Right)
                    if (hasVoice)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(
                              color: AppColors.darkSage.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                voiceChannels.length == 1
                                    ? '1 canal de voz'
                                    : '${voiceChannels.length} canais de voz',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
                      server.name,
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
                      '${server.memberCount} membros · ${server.channels.length} canais',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Activity Status Pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkSage
                                : AppColors.lightSage)
                            .withValues(alpha: 0.08),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: (isDark
                                  ? AppColors.darkSage
                                  : AppColors.lightSage)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.radio,
                            size: 13,
                            color: isDark
                                ? AppColors.darkSage
                                : AppColors.lightSage,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Voz em Alta Definição',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkSage
                                    : AppColors.lightSage,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
