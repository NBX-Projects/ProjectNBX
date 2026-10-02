import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:justtalking/features/servers/widgets/invite_member_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ServerInfoCard extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  final ServerModel server;
  final int rolesCount;
  final int pendingRequestsCount;
  final Color selectedAccentColor;
  final VoidCallback onMembersUpdated;

  const ServerInfoCard({
    super.key,
    this.isMobile = false,
    required this.isDark,
    required this.server,
    required this.rolesCount,
    required this.pendingRequestsCount,
    required this.selectedAccentColor,
    required this.onMembersUpdated,
  });

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMAÇÕES DO SERVIDOR',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            LucideIcons.tag,
            'Categoria',
            server.category.isEmpty ? 'Geral' : server.category,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            server.isPublic ? LucideIcons.globe : LucideIcons.lock,
            'Visibilidade',
            server.isPublic ? 'Público' : 'Privado',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(context, LucideIcons.shield, 'Cargos', '$rolesCount'),
          if (server.isPublic) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              LucideIcons.userPlus,
              'Pedidos',
              pendingRequestsCount > 0
                  ? '$pendingRequestsCount pendente(s)'
                  : 'Nenhum',
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => InviteMemberDialog.show(
                context,
                server,
                onMembersUpdated: onMembersUpdated,
              ),
              icon: const Icon(LucideIcons.userPlus, size: 14),
              label: Text(
                'Convidar Membro',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: selectedAccentColor,
                side: BorderSide(
                  color: selectedAccentColor.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
