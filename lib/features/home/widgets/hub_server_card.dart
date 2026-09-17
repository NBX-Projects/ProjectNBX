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
    return 'COMUNIDADE GERAL';
  }

  IconData _getCategoryWatermarkIcon(ServerModel server) {
    final lower = '${server.category} ${server.name}'.toLowerCase();
    if (lower.contains('apex') || lower.contains('game') || lower.contains('jogos')) {
      return LucideIcons.gamepad2;
    }
    if (lower.contains('dev') || lower.contains('code') || lower.contains('tech') || lower.contains('prog')) {
      return LucideIcons.code;
    }
    if (lower.contains('race') || lower.contains('sim') || lower.contains('mans') || lower.contains('car')) {
      return LucideIcons.gauge;
    }
    if (lower.contains('fps') || lower.contains('cs2') || lower.contains('valorant')) {
      return LucideIcons.crosshair;
    }
    if (lower.contains('study') || lower.contains('estudo')) {
      return LucideIcons.bookOpen;
    }
    return LucideIcons.gamepad2;
  }

  Widget _buildAvatarFallback(ServerModel server, Color accentColor) {
    final isLightAccent = accentColor.computeLuminance() > 0.5;
    return Container(
      width: 44,
      height: 44,
      color: accentColor.withValues(alpha: 0.28),
      child: Center(
        child: Icon(
          LucideIcons.zap,
          size: 20,
          color: isLightAccent ? const Color(0xFF181926) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildServerAvatar(ServerModel server, Color accentColor, bool isDark) {
    final iconUrl = server.iconUrl?.trim();
    final hasCustomIcon = iconUrl != null && iconUrl.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF141520) : Colors.white,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: hasCustomIcon
            ? (iconUrl.startsWith('assets/')
                ? Image.asset(
                    iconUrl,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarFallback(server, accentColor),
                  )
                : Image.network(
                    iconUrl,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarFallback(server, accentColor),
                  ))
            : _buildAvatarFallback(server, accentColor),
      ),
    );
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
                  : accentColor.withValues(alpha: isDark ? 0.22 : 0.18),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Thumbnail / Banner
              Container(
                height: 96,
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
                      right: -8,
                      bottom: -8,
                      child: Icon(
                        _getCategoryWatermarkIcon(server),
                        size: 78,
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
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
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
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildServerAvatar(server, accentColor, isDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                server.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14.5,
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
                                '${server.memberCount} ${server.memberCount == 1 ? "membro" : "membros"} · ${server.channels.length} ${server.channels.length == 1 ? "canal" : "canais"}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Activity Status Pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (hasVoice
                                ? const Color(0xFF4ADE80)
                                : accentColor)
                            .withValues(alpha: isDark ? 0.08 : 0.06),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: (hasVoice
                                  ? const Color(0xFF4ADE80)
                                  : accentColor)
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasVoice ? LucideIcons.volume2 : LucideIcons.messageSquare,
                            size: 13,
                            color: hasVoice
                                ? (isDark
                                    ? const Color(0xFF4ADE80)
                                    : AppColors.lightSage)
                                : accentColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasVoice
                                  ? 'Voz em Alta Definição'
                                  : 'Canais de Texto Ativos',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 13,
                            color: isDark
                                ? AppColors.darkTextMuted.withValues(alpha: 0.6)
                                : AppColors.lightTextMuted.withValues(alpha: 0.6),
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
