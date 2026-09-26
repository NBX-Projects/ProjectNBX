import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/localization/app_strings.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/shortcuts/controllers/shortcuts_controller.dart';
import 'package:projectnbx/core/shortcuts/models/app_shortcut_action.dart';
import 'package:projectnbx/core/shortcuts/services/keyboard_shortcuts_service.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/updater/update_controller.dart';
import 'package:projectnbx/core/updater/widgets/update_banner.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/home/widgets/create_server_card.dart';
import 'package:projectnbx/features/home/widgets/hub_left_rail.dart';
import 'package:projectnbx/features/home/widgets/hub_right_panel.dart';
import 'package:projectnbx/features/home/widgets/hub_server_card.dart';
import 'package:projectnbx/features/home/widgets/public_server_card.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/public_server_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';
import 'package:projectnbx/features/servers/widgets/server_workspace_view.dart';
import 'package:projectnbx/features/settings/screens/settings_screen.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/widgets/quick_audio_device_menu.dart';
import 'package:window_manager/window_manager.dart';

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
  List<PublicServerModel> _publicServers = [];
  bool _isLoadingPublicServers = false;
  bool _isServerRightSidebarVisible = true;

  @override
  void initState() {
    super.initState();
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
    shortcuts.registerHandler(AppShortcutAction.navigateHome, _handleNavigateHome);
    shortcuts.registerHandler(AppShortcutAction.quickSearch, _handleQuickSearch);
    shortcuts.registerHandler(AppShortcutAction.toggleRightSidebar, _handleToggleSidebar);
    shortcuts.registerHandler(AppShortcutAction.openCreateServer, _handleOpenCreateServer);
    shortcuts.registerHandler(AppShortcutAction.quickAudioDevices, _handleQuickAudioDevices);
  }

  @override
  void dispose() {
    final shortcuts = KeyboardShortcutsService.instance;
    shortcuts.unregisterHandler(AppShortcutAction.navigateHome, _handleNavigateHome);
    shortcuts.unregisterHandler(AppShortcutAction.quickSearch, _handleQuickSearch);
    shortcuts.unregisterHandler(AppShortcutAction.toggleRightSidebar, _handleToggleSidebar);
    shortcuts.unregisterHandler(AppShortcutAction.openCreateServer, _handleOpenCreateServer);
    shortcuts.unregisterHandler(AppShortcutAction.quickAudioDevices, _handleQuickAudioDevices);
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
      setState(() => _isServerRightSidebarVisible = !_isServerRightSidebarVisible);
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
    final strings = ref.watch(stringsProvider);
    final user = authState.user;
    final allServers = serversState.servers;

    final servers = _searchQuery.trim().isEmpty
        ? allServers
        : allServers
            .where((s) => s.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()))
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
        child: isMobile && selectedServer != null
            ? ServerWorkspaceView(
                server: selectedServer,
                onBackToHome: () => setState(() => _activeTab = 'home'),
                onRightSidebarVisibilityChanged: (visible) =>
                    setState(() => _isServerRightSidebarVisible = visible),
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

                  // 2. MAIN HUB CONTENT OR ACTIVE SERVER WORKSPACE
                  Expanded(
                    child: Column(
                      children: [
                        // Top Custom Window Bar
                        _buildTopBar(
                          context,
                          isDark,
                          user,
                          totalVoiceCount,
                          strings,
                          voiceState,
                          voiceNotifier,
                          hideVoiceControls:
                              selectedServer != null &&
                              _isServerRightSidebarVisible,
                        ),

                        // Notification banner se houver atualização disponível
                        const UpdateBanner(),

                        // Workspace / Main Area
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
                                              // Hub Header (Início + Subtitle + Criar Servidor)
                                              _buildHubHeader(
                                                context,
                                                isDark,
                                                servers.length,
                                                totalVoiceCount,
                                                strings,
                                                isMobile: isMobile,
                                              ),

                                              const SizedBox(height: 20),

                                              // Server Sections
                                              _buildSectionTitle(
                                                isDark,
                                                strings.myServers,
                                                count: servers.length,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildCardGrid(servers),

                                              const SizedBox(height: 28),

                                              // Public Servers Discovery Section (não listar servidores que o usuário já participa)
                                              () {
                                                final myServerIds = allServers
                                                    .map((s) => s.id)
                                                    .toSet();
                                                final availablePublicServers =
                                                    _publicServers.where((pub) {
                                                      final matchesFilter = _searchQuery.trim().isEmpty ||
                                                          pub.server.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
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
                                    if (!isMobile) const HubRightPanel(),
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

  // ===========================================================================
  // TOP BAR
  // ===========================================================================
  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    UserModel? user,
    int voiceCount,
    AppStrings strings,
    VoiceState voiceState,
    VoiceStateNotifier voiceNotifier, {
    bool hideVoiceControls = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktopPlatform =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    final shortcutsState = ref.watch(shortcutsProvider);
    final searchShortcut =
        shortcutsState.getCombination(AppShortcutAction.quickSearch)?.toReadableString() ??
            'Ctrl K';

    final content = Container(
      width: double.infinity,
      height: 56,
      padding: EdgeInsets.only(left: 14, right: isDesktopPlatform ? 0 : 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GRUPO ESQUERDO: busca + badge de chamadas (único participante flex da Row)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMobile) ...[
                  Text(
                    'ProjectNBX',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ] else ...[
                  // Search Box (interativo com atalho dinâmico)
                  Flexible(
                    child: Container(
                      height: 40,
                      constraints: const BoxConstraints(maxWidth: 540),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInput
                            : AppColors.lightSurface,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(
                          color: _searchFocusNode.hasFocus
                              ? (isDark
                                  ? AppColors.darkBorderFocus
                                  : AppColors.lightBorderFocus)
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: _searchFocusNode.hasFocus ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.search,
                            size: 16,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: strings.searchPlaceholder,
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 14,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : const Color(0xFFF1F5F9),
                              borderRadius: AppRadius.borderXs,
                            ),
                            child: Text(
                              searchShortcut,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSage : AppColors.lightSage)
                          .withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderPill,
                      border: Border.all(
                        color:
                            (isDark ? AppColors.darkSage : AppColors.lightSage)
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
                            color: isDark
                                ? AppColors.darkSage
                                : AppColors.lightSage,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$voiceCount ${strings.inCallsBadge}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkSage
                                : AppColors.lightSage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // GRUPO DIREITO: ícones de voz/tema/config (tamanho fixo, sempre encostado na borda)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile && !hideVoiceControls) ...[
                // Minimalist Audio Controls
                GestureDetector(
                  onSecondaryTap: () => QuickAudioDeviceMenu.show(
                    context,
                    anchorKey: _topMicKey,
                    isInput: true,
                  ),
                  child: IconButton(
                    key: _topMicKey,
                    icon: Icon(
                      voiceState.isMicMuted
                          ? LucideIcons.micOff
                          : LucideIcons.mic,
                      size: 18,
                      color: voiceState.isMicMuted
                          ? (isDark
                                ? AppColors.darkDanger
                                : AppColors.lightDanger)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
                    tooltip: voiceState.isMicMuted ? 'Desmutar' : 'Mutar',
                    onPressed: () => voiceNotifier.toggleMic(),
                  ),
                ),
                GestureDetector(
                  onSecondaryTap: () => QuickAudioDeviceMenu.show(
                    context,
                    anchorKey: _topHeadphonesKey,
                    isInput: false,
                  ),
                  child: IconButton(
                    key: _topHeadphonesKey,
                    icon: Icon(
                      voiceState.isDeafened
                          ? LucideIcons.headphones
                          : LucideIcons.headphones,
                      size: 18,
                      color: voiceState.isDeafened
                          ? (isDark
                                ? AppColors.darkDanger
                                : AppColors.lightDanger)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
                    tooltip: voiceState.isDeafened
                        ? 'Ativar Áudio'
                        : 'Desativar Áudio',
                    onPressed: () => voiceNotifier.toggleDeafened(),
                  ),
                ),
              ],

              IconButton(
                icon: Icon(
                  isDark ? LucideIcons.sun : LucideIcons.moon,
                  size: 18,
                  color: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                ),
                tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),

              if (!isMobile) ...[
                const SizedBox(width: 4),
                // AFK / Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
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
              ],

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
              const SizedBox(width: 4),

              if (isDesktopPlatform) ...[
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
            ],
          ),
        ],
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isDesktopPlatform ? DragToMoveArea(child: content) : content,
    );
  }

  // ===========================================================================
  // HUB HEADER
  // ===========================================================================
  Widget _buildHubHeader(
    BuildContext context,
    bool isDark,
    int totalCommunities,
    int totalInVoice,
    AppStrings strings, {
    bool isMobile = false,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.hubTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderPill,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                onPressed: () => CreateServerDialog.show(context),
                icon: const Icon(LucideIcons.plus, size: 15),
                label: Text(
                  strings.createServer,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.hubSubtitle(totalCommunities, totalInVoice),
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      );
    }

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
            backgroundColor: isDark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderPill,
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
            mainAxisExtent: 212,
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
