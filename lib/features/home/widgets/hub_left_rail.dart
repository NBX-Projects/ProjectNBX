import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';
import 'package:projectnbx/features/settings/screens/settings_screen.dart';

class HubLeftRail extends ConsumerWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const HubLeftRail({
    super.key,
    this.activeTab = 'home',
    required this.onTabChanged,
  });

  void _handleTabTap(BuildContext context, WidgetRef ref, String id) {
    onTabChanged(id);
    if (id != 'home') {
      final strings = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 320,
          backgroundColor: const Color(0xFF1E2030),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
            side: BorderSide(color: Color(0xFF313244)),
          ),
          content: Row(
            children: [
              const Icon(
                LucideIcons.hammer,
                size: 16,
                color: Color(0xFFF5CBA7),
              ),
              const SizedBox(width: 10),
              Text(
                strings.underConstruction,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final serversState = ref.watch(serversControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? user?.username ?? 'Taui';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final strings = ref.watch(stringsProvider);
    final servers = serversState.servers;

    final navItems = [
      {'id': 'home', 'icon': LucideIcons.house, 'tooltip': strings.navHome},
    ];

    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // 0. ProjectNBX Brand Logo Icon (non-clickable with theme color)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Center(
                    child: Icon(
                      LucideIcons.zap,
                      size: 24,
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // 1. Navigation Shortcut Icons
                ...navItems.map((item) {
                  final id = item['id'] as String;
                  final icon = item['icon'] as IconData;
                  final tooltip = item['tooltip'] as String;
                  final isSelected = activeTab == id;

                  return _buildRailButton(
                    context: context,
                    isDark: isDark,
                    isSelected: isSelected,
                    tooltip: tooltip,
                    icon: icon,
                    onTap: () => _handleTabTap(context, ref, id),
                  );
                }),

                const SizedBox(height: 6),

                // 2. Real Servers List from PostgreSQL
                ...servers.map((server) {
                  final isSelected = activeTab == server.id;
                  return _buildServerBadge(
                    context: context,
                    isDark: isDark,
                    server: server,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(serversControllerProvider.notifier)
                          .selectServer(server.id);
                      onTabChanged(server.id);
                    },
                  );
                }),

                // 3. Add Server (+) Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildAddServerButton(context, isDark, strings.createServer),
                ),
              ],
            ),
          ),

          // User Profile Avatar at Bottom of Left Rail
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Tooltip(
              message: '$displayName (${user?.username ?? ''})\nConfigurações de Perfil',
              preferBelow: false,
              textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2030),
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Center(
                child: InkWell(
                  onTap: () => SettingsScreen.show(context),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: AppRadius.borderPill,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkLavender
                          : AppColors.lightLavender,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF43B581),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailButton({
    required BuildContext context,
    required bool isDark,
    required bool isSelected,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2030),
          borderRadius: AppRadius.borderSm,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Center(
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: isSelected ? AppRadius.borderMd : AppRadius.borderPill,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated)
                    : Colors.transparent,
                borderRadius: isSelected ? AppRadius.borderMd : AppRadius.borderPill,
                border: isSelected
                    ? Border.all(
                        color: isDark
                            ? AppColors.darkBorderFocus
                            : AppColors.lightBorderFocus,
                      )
                    : null,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerBadge({
    required BuildContext context,
    required bool isDark,
    required ServerModel server,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final initials = server.name.isNotEmpty
        ? server.name
              .substring(0, server.name.length >= 2 ? 2 : 1)
              .toUpperCase()
        : 'S';
    final accentColor = Color(server.accentColor);
    final hasCustomIcon =
        server.iconUrl != null && server.iconUrl!.trim().isNotEmpty;
    final isLightAccent = accentColor.computeLuminance() > 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: server.name,
        preferBelow: false,
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2030),
          borderRadius: AppRadius.borderSm,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Center(
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: isSelected ? AppRadius.borderMd : AppRadius.borderPill,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: isSelected ? AppRadius.borderMd : AppRadius.borderPill,
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : accentColor.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius:
                    isSelected ? AppRadius.borderMd : AppRadius.borderPill,
                child: Center(
                  child: hasCustomIcon
                      ? Image.network(
                          server.iconUrl!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          errorBuilder: (context, error, stackTrace) => Text(
                            initials,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? (isLightAccent
                                        ? const Color(0xFF181926)
                                        : Colors.white)
                                  : accentColor,
                            ),
                          ),
                        )
                      : Text(
                          initials,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? (isLightAccent
                                      ? const Color(0xFF181926)
                                      : Colors.white)
                                : accentColor,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddServerButton(
    BuildContext context,
    bool isDark,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Center(
        child: InkWell(
          onTap: () => CreateServerDialog.show(context),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: AppRadius.borderPill,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Center(
              child: Icon(
                LucideIcons.plus,
                size: 18,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
