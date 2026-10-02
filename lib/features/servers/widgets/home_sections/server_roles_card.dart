import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:justtalking/features/servers/models/server_role_model.dart';
import 'package:justtalking/features/servers/widgets/server_roles_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ServerRolesCard extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  final ServerModel server;
  final List<ServerRoleModel> roles;
  final Color selectedAccentColor;
  final VoidCallback onRolesUpdated;

  const ServerRolesCard({
    super.key,
    this.isMobile = false,
    required this.isDark,
    required this.server,
    required this.roles,
    required this.selectedAccentColor,
    required this.onRolesUpdated,
  });

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 15,
                    color: selectedAccentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CARGOS DO SERVIDOR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings2, size: 14),
                tooltip: 'Gerenciar cargos',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                color: selectedAccentColor,
                onPressed: () => ServerRolesDialog.show(
                  context,
                  server,
                  onRolesUpdated: onRolesUpdated,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (roles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum cargo personalizado criado.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: roles.map((r) {
                final roleColor = Color(r.color);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: roleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        r.name,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
