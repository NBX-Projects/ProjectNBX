import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/models/public_server_model.dart';

class PublicServerCard extends ConsumerStatefulWidget {
  final PublicServerModel publicServer;
  final VoidCallback onOpenServer;
  final VoidCallback onRequestSubmitted;

  const PublicServerCard({
    super.key,
    required this.publicServer,
    required this.onOpenServer,
    required this.onRequestSubmitted,
  });

  @override
  ConsumerState<PublicServerCard> createState() => _PublicServerCardState();
}

class _PublicServerCardState extends ConsumerState<PublicServerCard> {
  bool _isHovered = false;
  bool _isSubmitting = false;

  Future<void> _showJoinRequestDialog() async {
    final messageController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
          title: Text(
            'Pedir para entrar no servidor',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Envie uma mensagem aos moderadores de "${widget.publicServer.server.name}":',
                style: GoogleFonts.inter(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Por que você gostaria de participar?',
                  filled: true,
                  fillColor:
                      isDark ? AppColors.darkInput : AppColors.lightCanvas,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(widget.publicServer.server.accentColor != 0 ? widget.publicServer.server.accentColor : 0xFFF5CBA7),
                foregroundColor: Color(widget.publicServer.server.accentColor != 0 ? widget.publicServer.server.accentColor : 0xFFF5CBA7).computeLuminance() > 0.5 ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Text(
                'Enviar Pedido',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSubmit == true && mounted) {
      setState(() => _isSubmitting = true);
      final apiClient = ref.read(apiClientProvider);

      try {
        await apiClient.createJoinRequest(
          widget.publicServer.server.id,
          message: messageController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              content: Text(
                'Solicitação de entrada enviada com sucesso! Aguarde a aprovação dos moderadores.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          widget.onRequestSubmitted();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(e.toString()),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.publicServer.server;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        AppColors.getBannerGradient(server.bannerPreset, server.id);
    final isMember = widget.publicServer.isMember;
    final status = widget.publicServer.joinRequestStatus;
    final accentColor = Color(server.accentColor != 0 ? server.accentColor : 0xFFF5CBA7);
    final isLightAccent = accentColor.computeLuminance() > 0.5;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: _isHovered
                ? accentColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Topo
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: AppRadius.topMd,
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.globe,
                            size: 10,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            server.category,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF141520) : Colors.white,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: ClipOval(
                          child: (server.iconUrl != null &&
                                  server.iconUrl!.trim().isNotEmpty)
                              ? Image.network(
                                  server.iconUrl!.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Text(
                                      server.name.isNotEmpty
                                          ? server.name[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    server.name.isNotEmpty
                                          ? server.name[0].toUpperCase()
                                          : '?',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${server.memberCount} ${server.memberCount == 1 ? "membro" : "membros"}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Botão de Ação
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(isMember, status, accentColor, isLightAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isMember, String status, Color accentColor, bool isLightAccent) {
    if (isMember) {
      return ElevatedButton(
        onPressed: widget.onOpenServer,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: isLightAccent ? const Color(0xFF181926) : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: Text(
          'Entrar no Servidor',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (status == 'pending') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(LucideIcons.clock, size: 12),
        label: Text(
          'Pedido Enviado',
          style: GoogleFonts.jetBrainsMono(fontSize: 10.5),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      );
    }

    if (status == 'rejected') {
      return OutlinedButton.icon(
        onPressed: _showJoinRequestDialog,
        icon: const Icon(LucideIcons.xCircle, size: 12, color: Colors.redAccent),
        label: Text(
          'Recusado (Tentar de novo)',
          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.redAccent),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _showJoinRequestDialog,
      icon: _isSubmitting
          ? SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isLightAccent ? const Color(0xFF181926) : Colors.white,
              ),
            )
          : Icon(
              LucideIcons.userPlus,
              size: 13,
              color: isLightAccent ? const Color(0xFF181926) : Colors.white,
            ),
      label: Text(
        'Pedir para entrar',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isLightAccent ? const Color(0xFF181926) : Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: isLightAccent ? const Color(0xFF181926) : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }
}
