import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/shortcuts/models/app_shortcut_action.dart';
import 'package:projectnbx/core/shortcuts/services/keyboard_shortcuts_service.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/updater/update_controller.dart';
import 'package:projectnbx/core/updater/widgets/update_banner.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/home/widgets/hub_left_rail.dart';
import 'package:projectnbx/features/home/widgets/hub_right_panel.dart';
import 'package:projectnbx/features/home/widgets/public_server_card.dart';
import 'package:projectnbx/features/home/widgets/sections/hub_header.dart';
import 'package:projectnbx/features/home/widgets/sections/hub_server_sections.dart';
import 'package:projectnbx/features/home/widgets/topbar/hub_top_bar.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/public_server_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';
import 'package:projectnbx/features/servers/widgets/server_workspace_view.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/widgets/quick_audio_device_menu.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeTab = 'home';
  final GlobalKey _topMicKey = GlobalKey();
  final GlobalKey _topHeadphonesKey = GlobalKey();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isServerRightSidebarVisible = true;
  List<PublicServerModel> _publicServers = [];
  bool _isLoadingPublicServers = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
    _loadPublicServers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb &&
          !Platform.environment.containsKey('FLUTTER_TEST') &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        ref
            .read(updateControllerProvider.notifier)
            .checkForUpdates(silent: true);
      }
    });

    final shortcuts = KeyboardShortcutsService.instance;
    shortcuts.registerHandler(
      AppShortcutAction.navigateHome,
      _handleNavigateHome,
    );
    shortcuts.registerHandler(
      AppShortcutAction.quickSearch,
      _handleQuickSearch,
    );
    shortcuts.registerHandler(
      AppShortcutAction.toggleRightSidebar,
      _handleToggleSidebar,
    );
    shortcuts.registerHandler(
      AppShortcutAction.openCreateServer,
      _handleOpenCreateServer,
    );
    shortcuts.registerHandler(
      AppShortcutAction.quickAudioDevices,
      _handleQuickAudioDevices,
    );
  }

  @override
  void dispose() {
    final shortcuts = KeyboardShortcutsService.instance;
    shortcuts.unregisterHandler(
      AppShortcutAction.navigateHome,
      _handleNavigateHome,
    );
    shortcuts.unregisterHandler(
      AppShortcutAction.quickSearch,
      _handleQuickSearch,
    );
    shortcuts.unregisterHandler(
      AppShortcutAction.toggleRightSidebar,
      _handleToggleSidebar,
    );
    shortcuts.unregisterHandler(
      AppShortcutAction.openCreateServer,
      _handleOpenCreateServer,
    );
    shortcuts.unregisterHandler(
      AppShortcutAction.quickAudioDevices,
      _handleQuickAudioDevices,
    );
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleNavigateHome() {
    if (mounted && _activeTab != 'home') {
      setState(() => _activeTab = 'home');
    }
  }

  void _handleQuickSearch() {
    if (mounted) {
      if (_activeTab != 'home') {
        setState(() => _activeTab = 'home');
      }
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    }
  }

  void _handleToggleSidebar() {
    if (mounted && _activeTab == 'home') {
      setState(
        () => _isServerRightSidebarVisible = !_isServerRightSidebarVisible,
      );
    }
  }

  void _handleOpenCreateServer() {
    if (mounted) {
      CreateServerDialog.show(context);
    }
  }

  void _handleQuickAudioDevices() {
    if (mounted) {
      QuickAudioDeviceMenu.show(context, anchorKey: _topMicKey, isInput: true);
    }
  }

  Future<void> _loadPublicServers() async {
    setState(() => _isLoadingPublicServers = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final list = await apiClient.getPublicServers();
      if (mounted) {
        setState(() {
          _publicServers = list;
          _isLoadingPublicServers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPublicServers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eagerly initialize and watch WebSocket client so it connects on login/restore session
    ref.watch(websocketClientProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final serversState = ref.watch(serversControllerProvider);
    final user = authState.user;
    final allServers = serversState.servers;

    final servers = _searchQuery.trim().isEmpty
        ? allServers
        : allServers
              .where(
                (s) => s.name.toLowerCase().contains(
                  _searchQuery.trim().toLowerCase(),
                ),
              )
              .toList();

    const totalVoiceCount = 0;

    final selectedServer = allServers.cast<ServerModel?>().firstWhere(
      (s) => s?.id == _activeTab,
      orElse: () => null,
    );

    final voiceState = ref.watch(voiceStateProvider);
    final voiceNotifier = ref.read(voiceStateProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            // Top Custom Window Bar (de um canto ao outro)
            HubTopBar(
              user: user,
              isDark: isDark,
              totalInVoice: totalVoiceCount,
              voiceState: voiceState,
              voiceNotifier: voiceNotifier,
              onToggleTheme: () =>
                  ref.read(themeModeProvider.notifier).toggleTheme(),
              onOpenSearch: _handleQuickSearch,
              topMicKey: _topMicKey,
              topHeadphonesKey: _topHeadphonesKey,
            ),

            // Notification banner se houver atualização disponível
            const UpdateBanner(),

            // Layout Principal (Left Rail + Workspace / Hub)
            Expanded(
              child: isMobile && selectedServer != null
                  ? ServerWorkspaceView(
                      server: selectedServer,
                      onBackToHome: () => setState(() => _activeTab = 'home'),
                      onRightSidebarVisibilityChanged: (visible) => setState(
                        () => _isServerRightSidebarVisible = visible,
                      ),
                    )
                  : Row(
                      children: [
                        HubLeftRail(
                          activeTab: _activeTab,
                          onTabChanged: (tab) {
                            setState(() => _activeTab = tab);
                            if (tab != 'home') {
                              ref
                                  .read(serversControllerProvider.notifier)
                                  .selectServer(tab);
                            }
                          },
                        ),

                        // MAIN HUB CONTENT OR ACTIVE SERVER WORKSPACE
                        Expanded(
                          child: selectedServer != null
                              ? ServerWorkspaceView(
                                  server: selectedServer,
                                  onBackToHome: () =>
                                      setState(() => _activeTab = 'home'),
                                  onRightSidebarVisibilityChanged: (visible) =>
                                      setState(
                                        () => _isServerRightSidebarVisible =
                                            visible,
                                      ),
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Center Content
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.topLeft,
                                        color: isDark
                                            ? AppColors.darkCanvas
                                            : AppColors.lightCanvas,
                                        child: SingleChildScrollView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 14 : 24,
                                            vertical: isMobile ? 14 : 20,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Hub Header (Início + Subtitle + Explorar)
                                              HubHeader(
                                                totalCommunities:
                                                    servers.length,
                                                totalInVoice: totalVoiceCount,
                                                onExplore: () =>
                                                    CreateServerDialog.show(
                                                      context,
                                                    ),
                                              ),

                                              const SizedBox(height: 20),

                                              // Lista de servidores do usuário
                                              HubServerSections(
                                                servers: servers,
                                                onSelectServer: (serverId) {
                                                  ref
                                                      .read(
                                                        serversControllerProvider
                                                            .notifier,
                                                      )
                                                      .selectServer(serverId);
                                                  setState(
                                                    () => _activeTab = serverId,
                                                  );
                                                },
                                              ),

                                              const SizedBox(height: 28),

                                              // Public Servers Discovery Section (não listar servidores que o usuário já participa)
                                              () {
                                                final myServerIds = allServers
                                                    .map((s) => s.id)
                                                    .toSet();
                                                final availablePublicServers =
                                                    _publicServers.where((pub) {
                                                      final matchesFilter =
                                                          _searchQuery
                                                              .trim()
                                                              .isEmpty ||
                                                          pub.server.name
                                                              .toLowerCase()
                                                              .contains(
                                                                _searchQuery
                                                                    .trim()
                                                                    .toLowerCase(),
                                                              );
                                                      return matchesFilter &&
                                                          !pub.isMember &&
                                                          !myServerIds.contains(
                                                            pub.server.id,
                                                          );
                                                    }).toList();

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildSectionTitle(
                                                      isDark,
                                                      'EXPLORAR SERVIDORES PÚBLICOS',
                                                      count:
                                                          availablePublicServers
                                                              .length,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildPublicServersGrid(
                                                      availablePublicServers,
                                                    ),
                                                  ],
                                                );
                                              }(),

                                              const SizedBox(height: 32),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Right Activity & Telemetry Sidebar (only visible on tablet/desktop)
                                    if (!isMobile &&
                                        _isServerRightSidebarVisible)
                                      const HubRightPanel(),
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

  Widget _buildSectionTitle(bool isDark, String title, {int? count}) {
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

  Widget _buildPublicServersGrid(List<PublicServerModel> publicServers) {
    if (_isLoadingPublicServers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (publicServers.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.globe, size: 20, color: Color(0xFFF5CBA7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhum servidor público disponível no momento',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Crie um servidor com visibilidade pública para que outros possam encontrá-lo e solicitar entrada.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
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
    }

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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: publicServers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 172,
          ),
          itemBuilder: (context, index) {
            final pub = publicServers[index];
            return PublicServerCard(
              publicServer: pub,
              onOpenServer: () {
                ref
                    .read(serversControllerProvider.notifier)
                    .selectServer(pub.server.id);
                setState(() => _activeTab = pub.server.id);
              },
              onRequestSubmitted: _loadPublicServers,
            );
          },
        );
      },
    );
  }
}
