import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
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
    return 'GERAL';
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
    final name = server.name.trim();
    return Container(
      width: 44,
      height: 44,
      color: accentColor.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
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
          color: Colors.white.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
    final accentColor = Color(server.accentColor != 0 ? server.accentColor : 0xFFF5CBA7);
    final isLightAccent = accentColor.computeLuminance() > 0.5;

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
              // 1. Top Thumbnail / Banner com Foto do Servidor
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
                      left: 10,
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

                    // Foto do Servidor na parte roxa (banner)
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: _buildServerAvatar(server, accentColor, isDark),
                    ),
                  ],
                ),
              ),

              // 2. Conteúdo do Card com Nome, Membros e Botão Entrar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 10),

                    // Botão Entrar na cor default do servidor
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isLightAccent
                              ? const Color(0xFF181926)
                              : Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: Text(
                          'Entrar',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
