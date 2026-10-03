import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/servers/models/channel_model.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HubServerCard extends StatefulWidget {
  final ServerModel server;
  final VoidCallback? onTap;

  const HubServerCard({super.key, required this.server, this.onTap});

  @override
  State<HubServerCard> createState() => _HubServerCardState();
}

class _HubServerCardState extends State<HubServerCard> {
  bool _isHovered = false;

  List<Color> _getGradientForServer(ServerModel server) {
    return AppColors.getBannerGradient(server.bannerPreset, server.id);
  }

  String _getCategoryForServer(ServerModel server) {
    final cat = server.category.trim();
    if (cat.isNotEmpty) {
      return cat.toUpperCase();
    }
    return 'GERAL';
  }

  IconData _getCategoryWatermarkIcon(ServerModel server) {
    final cat = server.category.toLowerCase().trim();
    if (cat.contains('game') ||
        cat.contains('jogo') ||
        cat.contains('gaming')) {
      return LucideIcons.gamepad2;
    }
    if (cat.contains('dev') ||
        cat.contains('code') ||
        cat.contains('tech') ||
        cat.contains('prog') ||
        cat.contains('programação')) {
      return LucideIcons.code;
    }
    if (cat.contains('race') ||
        cat.contains('sim') ||
        cat.contains('corrida')) {
      return LucideIcons.gauge;
    }
    if (cat.contains('study') || cat.contains('estudo')) {
      return LucideIcons.bookOpen;
    }
    if (cat.contains('music') || cat.contains('música')) {
      return LucideIcons.music;
    }
    if (cat.contains('design') || cat.contains('arte')) {
      return LucideIcons.palette;
    }
    if (cat.contains('cripto') || cat.contains('finan')) {
      return LucideIcons.coins;
    }
    return LucideIcons.users;
  }

  Color _getCategoryColor(String category, Color fallbackAccent) {
    final c = category.toUpperCase().trim();
    if (c.contains('GAMING') || c.contains('JOGO')) {
      return const Color(0xFF4F46E5);
    }
    if (c.contains('RACE') ||
        c.contains('SIM') ||
        c.contains('MANS') ||
        c.contains('CORRIDA')) {
      return const Color(0xFFD97706);
    }
    if (c.contains('DEV') ||
        c.contains('PROG') ||
        c.contains('CODE') ||
        c.contains('TECH') ||
        c.contains('PROGRAMAÇÃO')) {
      return const Color(0xFF2563EB);
    }
    if (c.contains('ESTUDO') || c.contains('STUDY')) {
      return const Color(0xFF059669);
    }
    if (c.contains('FPS') ||
        c.contains('CS2') ||
        c.contains('VALORANT') ||
        c.contains('APEX')) {
      return const Color(0xFFE11D48);
    }
    if (c.contains('MÚSICA') || c.contains('MUSIC')) {
      return const Color(0xFF7C3AED);
    }
    if (c.contains('DESIGN') || c.contains('ARTE')) {
      return const Color(0xFFDB2777);
    }
    if (c.contains('CRIPTO') || c.contains('FINAN')) {
      return const Color(0xFF10B981);
    }
    if (c.contains('COMUNIDADE') || c.contains('GERAL')) {
      return const Color(0xFF475569);
    }
    return fallbackAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final server = widget.server;
    final category = _getCategoryForServer(server);
    final gradient = _getGradientForServer(server);
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final accentColor = Color(
      server.accentColor != 0 ? server.accentColor : 0xFFF5CBA7,
    );
    final categoryColor = _getCategoryColor(category, accentColor);
    final categoryTextColor = categoryColor.computeLuminance() > 0.45
        ? const Color(0xFF141520)
        : Colors.white;

    // Apenas contar membros reais ativos em canais de voz/híbridos
    final voiceUsersCount = server.channels
        .where(
          (c) => c.type == ChannelType.voice || c.type == ChannelType.hybrid,
        )
        .fold<int>(0, (sum, c) => sum + c.activeMembers.length);

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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: surfaceColor,
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
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.05,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Cover / Banner com imagem e efeito de fade ("desaparecer")
              ClipRRect(
                borderRadius: AppRadius.topLg,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  height: 124,
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
                    fit: StackFit.expand,
                    clipBehavior: Clip.antiAlias,
                    children: [
                      if (server.bannerUrl != null &&
                          server.bannerUrl!.trim().isNotEmpty) ...[
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: AppRadius.topLg,
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              server.bannerUrl!.trim(),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],

                      if (server.bannerUrl == null ||
                          server.bannerUrl!.trim().isEmpty)
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Icon(
                            _getCategoryWatermarkIcon(server),
                            size: 78,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),

                      // Escurecimento suave cinematográfico
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.20),
                        ),
                      ),

                      // Vignette lateral/superior para destacar badges
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.55],
                            ),
                          ),
                        ),
                      ),

                      // Fusão suave na base: o banner se junta ao fundo do card ("desaparecer")
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                surfaceColor.withValues(alpha: 0.0),
                                surfaceColor.withValues(alpha: 0.0),
                                surfaceColor.withValues(alpha: 0.30),
                                surfaceColor.withValues(alpha: 0.75),
                                surfaceColor,
                              ],
                              stops: const [0.0, 0.30, 0.60, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Top-Left Category Pill (estilo protótipo com contraste garantido)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: AppRadius.borderSm,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: categoryTextColor,
                            ),
                          ),
                        ),
                      ),

                      // Top-Right Badge (Privado se não for público)
                      if (!server.isPublic)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.60),
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.lock,
                              size: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),

                      // Bottom-Right Pill no Banner (apenas se houver pessoas conectadas em voz)
                      if (voiceUsersCount > 0)
                        Positioned(
                          bottom: 9,
                          right: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.70),
                              borderRadius: AppRadius.borderPill,
                              border: Border.all(
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF22C55E),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF22C55E),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$voiceUsersCount em voz',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF22C55E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Conteúdo do Card (Nome, Membros e Pílula de Atividade)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            server.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isHovered ? 1.0 : 0.0,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 180),
                            offset: _isHovered
                                ? Offset.zero
                                : const Offset(-0.3, 0),
                            child: Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${server.memberCount} ${server.memberCount == 1 ? "membro" : "membros"}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Pílula inferior de atividade/descrição (fiel ao protótipo)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6.5,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: isDark ? 0.08 : 0.05,
                        ),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: accentColor.withValues(
                            alpha: isDark ? 0.22 : 0.18,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            server.description.trim().isNotEmpty
                                ? LucideIcons.activity
                                : LucideIcons.hash,
                            size: 13,
                            color: accentColor,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              server.description.trim().isNotEmpty
                                  ? server.description.trim()
                                  : '${server.channels.length} ${server.channels.length == 1 ? "canal ativo" : "canais ativos"}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? accentColor.withValues(alpha: 0.95)
                                    : accentColor,
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
