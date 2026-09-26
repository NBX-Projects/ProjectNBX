import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal dialog elegante para visualização de imagem em tela cheia com zoom e opção de download/salvar
class ImageLightboxDialog extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final bool isDark;

  const ImageLightboxDialog({
    super.key,
    required this.imageUrl,
    this.caption,
    this.isDark = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? caption,
    bool isDark = true,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => ImageLightboxDialog(
        imageUrl: imageUrl,
        caption: caption,
        isDark: isDark,
      ),
    );
  }

  Future<void> _handleSaveOrOpen(BuildContext context) async {
    try {
      final uri = Uri.parse(imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir a imagem externamente.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar/abrir imagem: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Imagem com zoom e pan interativo
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: AppRadius.borderMd,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      final expectedBytes = loadingProgress.expectedTotalBytes;
                      final loadedBytes = loadingProgress.cumulativeBytesLoaded;
                      final progress =
                          expectedBytes != null && expectedBytes > 0
                          ? loadedBytes / expectedBytes
                          : null;
                      return Container(
                        width: 320,
                        height: 240,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.5,
                          color: const Color(0xFFF5CBA7),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E2030),
                          borderRadius: AppRadius.borderMd,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.imageOff,
                              size: 40,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Não foi possível carregar a imagem',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Barra Superior de Ações (Salvar e Fechar)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão Salvar / Baixar
                    InkWell(
                      onTap: () => _handleSaveOrOpen(context),
                      borderRadius: AppRadius.borderPill,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.download,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Salvar Imagem',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 16,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    // Botão Fechar
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: AppRadius.borderPill,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Legenda Inferior (se houver)
            if (caption != null && caption!.trim().isNotEmpty)
              Positioned(
                bottom: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    caption!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
