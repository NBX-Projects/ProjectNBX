import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/config/app_config.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/core/updater/update_controller.dart';
import 'package:justtalking/core/updater/update_models.dart';
import 'package:justtalking/core/updater/widgets/update_dialog.dart';
import 'package:justtalking/features/settings/widgets/section_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SystemSection extends ConsumerWidget {
  final bool isDark;
  final AppStrings strings;
  final bool isMobile;

  const SystemSection({
    super.key,
    required this.isDark,
    required this.strings,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateControllerProvider);
    final isChecking = updateState.status == UpdateStatus.checking;
    final hasUpdate = updateState.status == UpdateStatus.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          isDark: isDark,
          title: strings.systemStatusTitle,
          description: strings.systemStatusDesc,
        ),
        const SizedBox(height: 24),

        // Versão & Atualizações Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                Row(
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
                            AppConfig.appName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'v${AppConfig.version}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (AppConfig.isDev
                                              ? (isDark
                                                    ? AppColors.darkLavender
                                                    : AppColors.lightLavender)
                                              : (isDark
                                                    ? AppColors.darkSage
                                                    : AppColors.lightSage))
                                          .withValues(alpha: 0.18),
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: Text(
                                  AppConfig.isDev ? 'DEV' : 'PROD',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppConfig.isDev
                                        ? (isDark
                                              ? AppColors.darkLavender
                                              : AppColors.lightLavender)
                                        : (isDark
                                              ? AppColors.darkSage
                                              : AppColors.lightSage),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: hasUpdate
                      ? ElevatedButton.icon(
                          onPressed: () => UpdateDialog.show(context),
                          icon: const Icon(LucideIcons.download, size: 14),
                          label: Text(
                            'Nova Versão (v${updateState.latestRelease?.version ?? ""})',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                            foregroundColor: isDark
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.borderPill,
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: isChecking
                              ? null
                              : () {
                                  ref
                                      .read(updateControllerProvider.notifier)
                                      .checkForUpdates(silent: false);
                                },
                          icon: isChecking
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                )
                              : const Icon(LucideIcons.refreshCw, size: 13),
                          label: Text(
                            isChecking
                                ? 'Verificando...'
                                : 'Verificar Atualizações',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                              borderRadius: AppRadius.borderSm,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConfig.appName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'v${AppConfig.version}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (AppConfig.isDev
                                                ? (isDark
                                                      ? AppColors.darkLavender
                                                      : AppColors.lightLavender)
                                                : (isDark
                                                      ? AppColors.darkSage
                                                      : AppColors.lightSage))
                                            .withValues(alpha: 0.18),
                                    borderRadius: AppRadius.borderXs,
                                  ),
                                  child: Text(
                                    AppConfig.isDev ? 'DEV' : 'PROD',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppConfig.isDev
                                          ? (isDark
                                                ? AppColors.darkLavender
                                                : AppColors.lightLavender)
                                          : (isDark
                                                ? AppColors.darkSage
                                                : AppColors.lightSage),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Botão de ação (Verificar ou Atualizar)
                    if (hasUpdate)
                      ElevatedButton.icon(
                        onPressed: () => UpdateDialog.show(context),
                        icon: const Icon(LucideIcons.download, size: 14),
                        label: Text(
                          'Nova Versão (v${updateState.latestRelease?.version ?? ""})',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderPill,
                          ),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: isChecking
                            ? null
                            : () {
                                ref
                                    .read(updateControllerProvider.notifier)
                                    .checkForUpdates(silent: false);
                              },
                        icon: isChecking
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              )
                            : const Icon(LucideIcons.refreshCw, size: 13),
                        label: Text(
                          isChecking
                              ? 'Verificando...'
                              : 'Verificar Atualizações',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                            borderRadius: AppRadius.borderSm,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (updateState.status == UpdateStatus.upToDate) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 14,
                      color: isDark ? AppColors.darkSage : AppColors.lightSage,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Você já está utilizando a versão mais recente.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkSage
                            : AppColors.lightSage,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'INFRAESTRUTURA DE SERVIÇOS',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        _buildServiceStatusCard(
          isDark: isDark,
          serviceName: 'Banco de Dados & Storage',
          endpoint: 'Armazenamento seguro de canais, contas e servidores',
          status: 'ONLINE & SINCRONIZADO',
          icon: LucideIcons.database,
          accentColor: isDark ? AppColors.darkSage : AppColors.lightSage,
          isMobile: isMobile,
        ),
        const SizedBox(height: 12),

        _buildServiceStatusCard(
          isDark: isDark,
          serviceName: 'Servidor de Voz & Transmissão',
          endpoint:
              'Áudio cristalino de alta fidelidade com latência ultrabaixa',
          status: 'PRONTO (< 50ms)',
          icon: LucideIcons.radio,
          accentColor: isDark
              ? AppColors.darkLavender
              : AppColors.lightLavender,
          isMobile: isMobile,
        ),
        const SizedBox(height: 12),

        _buildServiceStatusCard(
          isDark: isDark,
          serviceName: 'API Gateway & WebSocket Hub',
          endpoint:
              'Sincronização em tempo real de mensagens e status de presença',
          status: 'CONECTADO',
          icon: LucideIcons.server,
          accentColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildServiceStatusCard({
    required bool isDark,
    required String serviceName,
    required String endpoint,
    required String status,
    required IconData icon,
    required Color accentColor,
    bool isMobile = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Icon(icon, size: 18, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        serviceName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  endpoint,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        endpoint,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
