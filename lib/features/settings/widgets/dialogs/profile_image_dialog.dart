import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileImageDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required bool isAvatar,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.read(authControllerProvider).user;
    final currentUrl = isAvatar
        ? (user?.avatarUrl ?? '')
        : (user?.bannerUrl ?? '');

    final urlController = TextEditingController(text: currentUrl);
    String previewUrl = currentUrl;
    bool isUploading = false;
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (sbContext, setDialogState) {
            final cardBg = isDark
                ? AppColors.darkSurfaceElevated
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
            final primaryColor = isDark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary;
            final onPrimaryColor = isDark ? AppColors.darkCanvas : Colors.white;

            final isGif = previewUrl.toLowerCase().contains('.gif');

            Future<void> pickAndUpload() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const [
                    'png',
                    'jpg',
                    'jpeg',
                    'webp',
                    'gif',
                    'bmp',
                  ],
                  withData: true,
                );
                if (result != null && result.files.isNotEmpty) {
                  final picked = result.files.first;
                  setDialogState(() {
                    isUploading = true;
                    localError = null;
                  });

                  var bytes = picked.bytes;
                  if (bytes == null && !kIsWeb && picked.path != null) {
                    bytes = await File(picked.path!).readAsBytes();
                  }
                  if (bytes == null) {
                    setDialogState(() {
                      isUploading = false;
                      localError = 'Não foi possível ler o arquivo selecionado';
                    });
                    return;
                  }

                  final apiClient = ref.read(apiClientProvider);
                  final uploadRes = await apiClient.uploadMedia(
                    bytes: bytes,
                    filename: picked.name,
                  );

                  final newUrl = uploadRes['url'] as String? ?? '';
                  setDialogState(() {
                    isUploading = false;
                    previewUrl = newUrl;
                    urlController.text = newUrl;
                  });
                }
              } catch (e) {
                setDialogState(() {
                  isUploading = false;
                  localError = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
                side: BorderSide(color: borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAvatar ? LucideIcons.user : LucideIcons.image,
                            size: 18,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAvatar ? 'Foto de Perfil' : 'Capa de Perfil',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAvatar
                            ? 'Escolha um arquivo do computador (PNG, JPG, WEBP ou GIF animado) ou informe uma URL direta.'
                            : 'Personalize sua capa com uma imagem ou GIF animado para dar destaque ao seu perfil.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Preview Container
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isAvatar)
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? AppColors.darkLavender
                                      : AppColors.lightLavender,
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 2.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: previewUrl.isNotEmpty
                                      ? Image.network(
                                          previewUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Center(
                                                    child: Icon(
                                                      LucideIcons.imageOff,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                        )
                                      : Center(
                                          child: Icon(
                                            LucideIcons.user,
                                            size: 36,
                                            color: isDark
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.borderSm,
                                  color: isDark
                                      ? const Color(0xFF1E2030)
                                      : const Color(0xFFE2E8F0),
                                  border: Border.all(color: borderColor),
                                  image: previewUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(previewUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: previewUrl.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Nenhuma capa definida (usando padrão)',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            if (isGif && previewUrl.isNotEmpty)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'GIF ANIMADO',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botão Escolher Arquivo do Computador
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: isUploading ? null : pickAndUpload,
                          icon: isUploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.uploadCloud, size: 15),
                          label: Text(
                            isUploading
                                ? 'Enviando imagem...'
                                : 'Escolher Arquivo (Suporta GIF)',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.5),
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.borderPill,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: Divider(color: borderColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'OU URL DIRETA',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: borderColor)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Campo de URL direta
                      TextField(
                        controller: urlController,
                        style: TextStyle(color: textPrimary, fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'https://exemplo.com/imagem.gif',
                          prefixIcon: Icon(
                            LucideIcons.link,
                            size: 14,
                            color: textSecondary,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.check, size: 14),
                            tooltip: 'Carregar prévia',
                            onPressed: () {
                              setDialogState(() {
                                previewUrl = urlController.text.trim();
                              });
                            },
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            previewUrl = val.trim();
                          });
                        },
                      ),

                      if (localError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          localError!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.darkDanger,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (currentUrl.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                final notifier = ref.read(
                                  authControllerProvider.notifier,
                                );
                                if (isAvatar) {
                                  await notifier.updateProfile(avatarUrl: '');
                                } else {
                                  await notifier.updateProfile(bannerUrl: '');
                                }
                                if (dialogCtx.mounted) {
                                  Navigator.of(dialogCtx).pop();
                                }
                              },
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 13,
                                color: AppColors.darkDanger,
                              ),
                              label: Text(
                                'Remover',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AppColors.darkDanger,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: onPrimaryColor,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderPill,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        final newUrl = previewUrl.trim();
                                        final notifier = ref.read(
                                          authControllerProvider.notifier,
                                        );
                                        final ok = isAvatar
                                            ? await notifier.updateProfile(
                                                avatarUrl: newUrl,
                                              )
                                            : await notifier.updateProfile(
                                                bannerUrl: newUrl,
                                              );
                                        if (dialogCtx.mounted) {
                                          Navigator.of(dialogCtx).pop();
                                        }
                                        if (ok) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              backgroundColor: const Color(
                                                0xFF2D6A4F,
                                              ),
                                              content: Text(
                                                isAvatar
                                                    ? 'Foto de perfil atualizada!'
                                                    : 'Capa de perfil atualizada!',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: Text(
                                  'Salvar',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
