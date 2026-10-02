import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChangePasswordDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required bool isDark,
  }) async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final primaryColor = isDark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary;
            final onPrimaryColor = isDark ? AppColors.darkCanvas : Colors.white;
            final cardBg = isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface;
            final borderColor = isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder;
            final textPrimary = isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary;
            final textSecondary = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary;

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderLg,
                side: BorderSide(color: borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Icon(
                                LucideIcons.keyRound,
                                size: 20,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alterar Senha',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Confirme sua senha atual para definir uma nova',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: textSecondary,
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.15),
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(
                                color: const Color(
                                  0xFFE53935,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.triangleAlert,
                                  size: 16,
                                  color: Color(0xFFE53935),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          style: TextStyle(color: textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Senha Atual',
                            prefixIcon: Icon(
                              LucideIcons.lock,
                              size: 16,
                              color: textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureCurrent
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 16,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setDialogState(
                                  () => obscureCurrent = !obscureCurrent,
                                );
                              },
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Informe sua senha atual'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          style: TextStyle(color: textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Nova Senha',
                            prefixIcon: Icon(
                              LucideIcons.key,
                              size: 16,
                              color: textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNew
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 16,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setDialogState(() => obscureNew = !obscureNew);
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a nova senha';
                            }
                            if (v.length < 6) return 'Mínimo de 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          style: TextStyle(color: textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Confirmar Nova Senha',
                            prefixIcon: Icon(
                              LucideIcons.checkCheck,
                              size: 16,
                              color: textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 16,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setDialogState(
                                  () => obscureConfirm = !obscureConfirm,
                                );
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v != newPasswordController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: onPrimaryColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.borderPill,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setDialogState(() {
                                        isSaving = true;
                                        errorMessage = null;
                                      });
                                      final success = await ref
                                          .read(authControllerProvider.notifier)
                                          .changePassword(
                                            currentPassword:
                                                currentPasswordController.text,
                                            newPassword:
                                                newPasswordController.text,
                                          );
                                      if (!dialogContext.mounted) return;
                                      if (success) {
                                        Navigator.of(dialogContext).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(
                                              0xFF2D6A4F,
                                            ),
                                            content: Text(
                                              'Senha alterada com sucesso!',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        final err =
                                            ref
                                                .read(authControllerProvider)
                                                .errorMessage ??
                                            'Falha ao alterar senha';
                                        setDialogState(() {
                                          isSaving = false;
                                          errorMessage = err;
                                        });
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Salvar Nova Senha',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}
