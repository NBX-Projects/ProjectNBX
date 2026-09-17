import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';

class HubRightPanel extends ConsumerWidget {
  const HubRightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final serversState = ref.watch(serversControllerProvider);
    final strings = ref.watch(stringsProvider);
    final servers = serversState.servers;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        children: [
          // 1. Atividade Recente / Notificações
          _buildSectionHeader(
            isDark,
            strings.recentActivity,
            LucideIcons.bell,
          ),
          const SizedBox(height: 8),

          _buildEmptyStateCard(
            isDark: isDark,
            icon: LucideIcons.messageSquare,
            title: strings.noNotificationsTitle,
            subtitle: strings.noNotificationsSubtitle,
          ),

          const SizedBox(height: 16),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 12),

          // 2. Próximos Eventos
          _buildSectionHeader(
            isDark,
            strings.upcomingEvents,
            LucideIcons.calendar,
          ),
          const SizedBox(height: 8),

          _buildEmptyStateCard(
            isDark: isDark,
            icon: LucideIcons.calendarX,
            title: strings.noEventsTitle,
            subtitle: strings.noEventsSubtitle,
          ),

          const SizedBox(height: 16),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 12),

          // 3. Resumo dos Servidores do Usuário
          _buildSectionHeader(
            isDark,
            strings.communitySummary,
            LucideIcons.server,
            count: servers.length,
          ),
          const SizedBox(height: 8),

          if (servers.isEmpty) ...[
            _buildEmptyStateCard(
              isDark: isDark,
              icon: LucideIcons.plusCircle,
              title: strings.createFirstCommunityTitle,
              subtitle: strings.createFirstCommunitySubtitle,
              actionLabel: '+ ${strings.createServer}',
              onAction: () => CreateServerDialog.show(context),
            ),
          ] else ...[
            ...servers.take(5).map((server) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Center(
                        child: Text(
                          server.name.isNotEmpty
                              ? server.name[0].toUpperCase()
                              : 'S',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${server.channels.length} ${strings.isPt ? 'canais' : 'channels'} · ${server.memberCount} ${strings.isPt ? 'membros' : 'members'}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
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
              );
            }),
          ],

          const SizedBox(height: 16),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 12),

          // 4. Status da Conexão
          _buildSectionHeader(
            isDark,
            strings.systemAndNetwork,
            LucideIcons.activity,
          ),
          const SizedBox(height: 8),

          _buildStatusRow(
            isDark: isDark,
            label: strings.databaseService,
            status: strings.isPt ? 'Conectado' : 'Connected',
            isOnline: true,
          ),
          const SizedBox(height: 6),
          _buildStatusRow(
            isDark: isDark,
            label: strings.voiceService,
            status: strings.ready,
            isOnline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    bool isDark,
    String title,
    IconData icon, {
    int? count,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated,
              borderRadius: AppRadius.borderXs,
            ),
            child: Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyStateCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onAction,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: AppRadius.borderSm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorderFocus
                        : AppColors.lightBorderFocus,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required bool isDark,
    required String label,
    required String status,
    required bool isOnline,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? (isDark ? AppColors.darkSage : AppColors.lightSage)
                      : (isDark ? AppColors.darkDanger : AppColors.lightDanger),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isOnline
                ? (isDark ? AppColors.darkSage : AppColors.lightSage)
                : (isDark ? AppColors.darkDanger : AppColors.lightDanger),
          ),
        ),
      ],
    );
  }
}
