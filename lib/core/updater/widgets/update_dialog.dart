import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/updater/update_controller.dart';
import 'package:projectnbx/core/updater/update_models.dart';

class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const UpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final latest = updateState.latestRelease;

    final isDownloading = updateState.status == UpdateStatus.downloading;
    final isReadyToInstall = updateState.status == UpdateStatus.readyToInstall;

    String actionLabel = 'Baixar e Instalar';
    if (!kIsWeb && Platform.isAndroid) {
      actionLabel = 'Baixar APK';
    } else if (kIsWeb) {
      actionLabel = 'Ver no GitHub';
    }
    if (isDownloading) actionLabel = 'Baixando...';
    if (isReadyToInstall) actionLabel = 'Instalando...';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 20,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atualização do ProjectNBX',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'v${updateState.currentVersion}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                LucideIcons.arrowRight,
                                size: 12,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppColors.darkSage
                                            : AppColors.lightSage)
                                        .withValues(alpha: 0.2),
                                borderRadius: AppRadius.borderXs,
                              ),
                              child: Text(
                                'v${latest?.version ?? ""}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkSage
                                      : AppColors.lightSage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),

            // Content / Release Notes
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTAS DA VERSÃO',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 160,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkInput
                          : AppColors.lightSurfaceElevated,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        latest?.body.isNotEmpty == true
                            ? latest!.body
                            : 'Melhorias de desempenho, correções de bugs e aprimoramentos gerais de estabilidade.',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          height: 1.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),

                  // Progress Section if downloading
                  if (isDownloading || isReadyToInstall) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isReadyToInstall
                              ? 'Download concluído! Iniciando instalador...'
                              : 'Baixando atualização...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${(updateState.downloadProgress * 100).toInt()}%',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: AppRadius.borderXs,
                      child: LinearProgressIndicator(
                        value: updateState.downloadProgress,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                    ),
                    if (updateState.totalBytes > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(updateState.bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB / ${(updateState.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],

                  if (updateState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      updateState.errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkDanger
                            : AppColors.lightDanger,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),

            // Footer / Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(updateControllerProvider.notifier)
                          .openReleasePage();
                    },
                    icon: const Icon(LucideIcons.externalLink, size: 14),
                    label: Text(
                      'Ver no GitHub',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderPill,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Fechar',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: isDownloading || isReadyToInstall
                            ? null
                            : () {
                                ref
                                    .read(updateControllerProvider.notifier)
                                    .downloadAndInstall();
                              },
                        icon: Icon(
                          isDownloading
                              ? LucideIcons.loader
                              : LucideIcons.download,
                          size: 15,
                        ),
                        label: Text(
                          actionLabel,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderPill,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
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
