import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_radius.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const ConfirmDeleteDialog({
    super.key,
    this.title = 'Excluir Mensagem',
    this.message =
        'Tem certeza de que deseja apagar esta mensagem? Esta ação não pode ser desfeita e qualquer anexo será removido permanentemente.',
    this.confirmLabel = 'Excluir',
    this.cancelLabel = 'Cancelar',
  });

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Excluir Mensagem',
    String message =
        'Tem certeza de que deseja apagar esta mensagem? Esta ação não pode ser desfeita e qualquer anexo será removido permanentemente.',
    String confirmLabel = 'Excluir',
    String cancelLabel = 'Cancelar',
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => ConfirmDeleteDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181926) : const Color(0xFFFAF9F6),
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.trash2,
                        size: 20,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF282A3A) : const Color(0xFFE2E8F0),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF282A3A) : const Color(0xFFE2E8F0),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderPill,
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.trash2, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          confirmLabel,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
    );
  }
}
