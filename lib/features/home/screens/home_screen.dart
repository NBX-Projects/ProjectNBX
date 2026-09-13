import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:projectnbx/core/localization/app_strings.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/home/widgets/create_server_card.dart';
import 'package:projectnbx/features/home/widgets/hub_left_rail.dart';
import 'package:projectnbx/features/home/widgets/hub_right_panel.dart';
import 'package:projectnbx/features/home/widgets/hub_server_card.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';
import 'package:projectnbx/features/servers/widgets/server_workspace_view.dart';
import 'package:projectnbx/features/settings/screens/settings_screen.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeTab = 'home';
  bool _isMuted = false;
  bool _isDeafened = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final serversState = ref.watch(serversControllerProvider);
    final strings = ref.watch(stringsProvider);
    final user = authState.user;
    final servers = serversState.servers;

    const totalVoiceCount = 0;

    final selectedServer = servers.cast<ServerModel?>().firstWhere(
      (s) => s?.id == _activeTab,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Full-Width Top Bar
          _buildTopBar(context, isDark, user, totalVoiceCount, strings),

          // 2. Body: Left Rail + (Server Workspace OR Hub Grid + Right Panel)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Navigation Rail
                HubLeftRail(
                  activeTab: _activeTab,
                  onTabChanged: (tab) => setState(() => _activeTab = tab),
                ),

                // Main Stage: Server Workspace OR Hub Grid
                Expanded(
                  child: selectedServer != null
                      ? ServerWorkspaceView(
                          server: selectedServer,
                          onBackToHome: () => setState(() => _activeTab = 'home'),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Center Main Hub Grid
                            Expanded(
                              child: Container(
                                alignment: Alignment.topLeft,
                                color: isDark
                                    ? AppColors.darkCanvas
                                    : AppColors.lightCanvas,
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Hub Header (Início + Subtitle + Criar Servidor)
                                      _buildHubHeader(
                                        context,
                                        isDark,
                                        servers.length,
                                        totalVoiceCount,
                                        strings,
                                      ),

                                      const SizedBox(height: 24),

                                      // Server Sections
                                      _buildSectionTitle(
                                        isDark,
                                        strings.myServers,
                                        count: servers.length,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCardGrid(servers),

                                      const SizedBox(height: 32),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Right Activity & Telemetry Sidebar
                            const HubRightPanel(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================
  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    UserModel? user,
    int voiceCount,
    AppStrings strings,
  ) {
    final username = user?.username ?? 'Taui Lima';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DragToMoveArea(
        child: Container(
          width: double.infinity,
          height: 56,
          padding: const EdgeInsets.only(left: 16, right: 0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            // Logo Icon Badge (Clean & Modern)
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.zap,
                size: 18,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // Search Box
            Flexible(
              child: Container(
                height: 38,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkInput : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 15,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.searchPlaceholder,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ctrl K',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Voice Activity Pill Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSage : AppColors.lightSage)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: (isDark ? AppColors.darkSage : AppColors.lightSage)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkSage : AppColors.lightSage,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$voiceCount ${strings.inCallsBadge}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.darkSage : AppColors.lightSage,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Audio Quick Controls
            IconButton(
              icon: Icon(
                _isMuted ? LucideIcons.micOff : LucideIcons.mic,
                size: 18,
                color: _isMuted
                    ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              tooltip: _isMuted ? 'Desmutar' : 'Mutar',
              onPressed: () => setState(() => _isMuted = !_isMuted),
            ),
            IconButton(
              icon: Icon(
                _isDeafened ? LucideIcons.headphones : LucideIcons.headphones,
                size: 18,
                color: _isDeafened
                    ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              tooltip: _isDeafened ? 'Ativar Áudio' : 'Desativar Áudio',
              onPressed: () => setState(() => _isDeafened = !_isDeafened),
            ),
            IconButton(
              icon: Icon(
                isDark ? LucideIcons.sun : LucideIcons.moon,
                size: 18,
                color:
                    isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
              tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            const SizedBox(width: 6),

            // AFK / Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                strings.afk,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Settings Button (Configurações)
            IconButton(
              icon: Icon(
                LucideIcons.settings,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              tooltip: strings.navSettings,
              onPressed: () => SettingsScreen.show(context),
            ),
            const SizedBox(width: 6),

            // User Profile Pill with Logout
            InkWell(
              onTap: () {
                ref.read(authControllerProvider.notifier).logout();
              },
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkLavender
                            : AppColors.lightLavender,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      username,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.logOut,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Vertical Divider separating app bar and window buttons
            Container(
              height: 24,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),

            const SizedBox(width: 4),

            // Integrated Windows Window Controls
            const WindowControls(height: 56, buttonWidth: 46),
          ],
        ),
      ),
    ));
  }

  // ===========================================================================
  // HUB HEADER
  // ===========================================================================
  Widget _buildHubHeader(
    BuildContext context,
    bool isDark,
    int totalCommunities,
    int totalInVoice,
    AppStrings strings,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.hubTitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.hubSubtitle(totalCommunities, totalInVoice),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),

        // + Criar / Explorar Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () => CreateServerDialog.show(context),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: Text(
            strings.createServer,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    bool isDark,
    String title, {
    int? count,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardGrid(List<ServerModel> servers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
        }

        final itemCount = servers.isEmpty ? 1 : servers.length;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 220,
          ),
          itemBuilder: (context, index) {
            if (servers.isEmpty) {
              return const CreateServerCard();
            }
            final server = servers[index];
            return HubServerCard(
              server: server,
              onTap: () {
                ref
                    .read(serversControllerProvider.notifier)
                    .selectServer(server.id);
                setState(() => _activeTab = server.id);
              },
            );
          },
        );
      },
    );
  }
}
