import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';

enum ServerViewMode {
  home,
  channel,
}

enum ServerSidebarTab {
  canais,
  membros,
  resumo,
}

class ServerWorkspaceView extends ConsumerStatefulWidget {
  final ServerModel server;
  final VoidCallback onBackToHome;

  const ServerWorkspaceView({
    super.key,
    required this.server,
    required this.onBackToHome,
  });

  @override
  ConsumerState<ServerWorkspaceView> createState() => _ServerWorkspaceViewState();
}

class _ServerWorkspaceViewState extends ConsumerState<ServerWorkspaceView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, List<_ChatMessage>> _channelMessages = {};

  ServerViewMode _viewMode = ServerViewMode.home;
  ServerSidebarTab _activeSidebarTab = ServerSidebarTab.canais;
  ChannelModel? _activeChannel;

  int _selectedBannerPreset = 0;
  Color _selectedAccentColor = const Color(0xFFF5CBA7);
  bool _isCustomizingBanner = false;

  bool _isMicMuted = false;
  bool _isDeafened = false;
  bool _isInVoice = false;
  String? _connectedVoiceChannelId;

  // Real stream / screen share transmission state
  bool _isTransmitting = false;
  double _streamVolume = 0.75;
  bool _isChatMinimized = false;
  bool _isFullscreen = false;

  final List<List<Color>> _bannerPresets = [
    [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF4338CA)],
    [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
    [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF059669)],
    [const Color(0xFF450A0A), const Color(0xFF7F1D1D), const Color(0xFF991B1B)],
    [const Color(0xFF3B0764), const Color(0xFF581C87), const Color(0xFF6B21A8)],
  ];

  final List<Color> _accentPalette = [
    const Color(0xFFF5CBA7), // Pastel Peach
    const Color(0xFF4ADE80), // Pastel Sage
    const Color(0xFF38BDF8), // Cyan Blue
    const Color(0xFFF87171), // Coral Red
    const Color(0xFFC084FC), // Soft Lavender
  ];

  @override
  void initState() {
    super.initState();
    _selectedBannerPreset = widget.server.bannerPreset.clamp(0, _bannerPresets.length - 1);
    _selectedAccentColor = Color(widget.server.accentColor);
  }

  @override
  void didUpdateWidget(ServerWorkspaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id ||
        oldWidget.server.bannerPreset != widget.server.bannerPreset ||
        oldWidget.server.accentColor != widget.server.accentColor) {
      setState(() {
        _selectedBannerPreset = widget.server.bannerPreset.clamp(0, _bannerPresets.length - 1);
        _selectedAccentColor = Color(widget.server.accentColor);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String channelKey, String authorName) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMsg = _ChatMessage(
      author: authorName,
      authorColor: _selectedAccentColor,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _channelMessages.putIfAbsent(channelKey, () => []).add(newMsg);
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openHybridChannel(ChannelModel channel) {
    setState(() {
      _activeChannel = channel;
      _viewMode = ServerViewMode.channel;
      _isInVoice = true;
      _connectedVoiceChannelId = channel.id;
    });
    ref.read(serversControllerProvider.notifier).selectChannel(channel.id);
  }

  void _leaveVoice() {
    setState(() {
      _isInVoice = false;
      _isTransmitting = false;
      _connectedVoiceChannelId = null;
      _viewMode = ServerViewMode.home;
    });
  }

  void _toggleTransmission() {
    setState(() {
      _isTransmitting = !_isTransmitting;
      if (_isTransmitting) {
        _isInVoice = true;
        if (_activeChannel != null) {
          _connectedVoiceChannelId = _activeChannel!.id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final username = user?.username ?? 'Taui Lima';

    final effectiveChannels = widget.server.channels.isNotEmpty
        ? widget.server.channels
        : [
            ChannelModel(
              id: 'chn_geral',
              serverId: widget.server.id,
              name: 'geral',
              type: ChannelType.hybrid,
            ),
          ];

    return Column(
      children: [
        // 1. Sub-Header Navigation Bar
        _buildServerTopNav(context, isDark, username),

        // 2. Main Body: Stage (Home OR Hybrid Channel Stage) + Right Sidebar
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Stage (Home, Direct Chat, or Immersive Stream + HUD)
              Expanded(
                child: _viewMode == ServerViewMode.home
                    ? _buildServerHomeContent(context, isDark, username, effectiveChannels)
                    : _buildHybridChannelStage(context, isDark, username, effectiveChannels),
              ),

              // Right Sidebar (Canais | Membros | Resumo)
              _buildRightSidebar(
                context,
                isDark,
                effectiveChannels,
                username,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 1. SERVER SUB-HEADER NAVIGATION BAR
  // ===========================================================================
  Widget _buildServerTopNav(
    BuildContext context,
    bool isDark,
    String username,
  ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back to Hub Button
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            tooltip: 'Voltar ao Hub Principal',
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            onPressed: widget.onBackToHome,
          ),
          const SizedBox(width: 8),

          // Server Icon & Name
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              LucideIcons.server,
              size: 14,
              color: _selectedAccentColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.server.name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          if (_viewMode == ServerViewMode.channel && _activeChannel != null) ...[
            const SizedBox(width: 8),
            Text(
              '/',
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '# ${_activeChannel!.name}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _selectedAccentColor,
              ),
            ),
          ],

          const Spacer(),

          // Hub Pill Button
          InkWell(
            onTap: () => setState(() => _viewMode = ServerViewMode.home),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _viewMode == ServerViewMode.home
                    ? _selectedAccentColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _viewMode == ServerViewMode.home
                      ? Colors.transparent
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.layoutGrid,
                    size: 13,
                    color: _viewMode == ServerViewMode.home
                        ? Colors.black
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hub',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _viewMode == ServerViewMode.home
                          ? Colors.black
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // User Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2030) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _selectedAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  username,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _selectedAccentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Owner',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: _selectedAccentColor,
                    ),
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
  // 2. HYBRID CHANNEL STAGE
  // ===========================================================================
  Widget _buildHybridChannelStage(
    BuildContext context,
    bool isDark,
    String username,
    List<ChannelModel> channels,
  ) {
    final activeChannelName = _activeChannel?.name ?? 'geral';
    final channelKey = _activeChannel?.id ?? 'default';
    final messages = _channelMessages[channelKey] ?? [];

    // CASO 1: SEM TRANSMISSÃO -> Mostra o Chat diretamente em tela inteira
    if (!_isTransmitting) {
      return _buildDirectChatView(
        context,
        isDark,
        activeChannelName,
        channelKey,
        username,
        messages,
      );
    }

    // CASO 2: COM TRANSMISSÃO -> Mostra Palco de Vídeo/Tela + Chat Flutuante HUD
    return Container(
      color: const Color(0xFF0C0D14),
      child: Stack(
        children: [
          // A. Palco Imersivo de Transmissão / Screen Share
          Positioned.fill(
            child: _buildImmersiveStreamPlayer(isDark, username),
          ),

          // B. Barra Inferior da Transmissão (Volume, Tela Cheia, PiP)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStageBottomControlBar(isDark, username),
          ),

          // C. Chat Flutuante HUD (Glassmorphism Overlay)
          Positioned(
            top: 20,
            right: 20,
            width: 330,
            height: _isChatMinimized ? 44 : 390,
            child: _buildFloatingChatHud(
              context,
              isDark,
              activeChannelName,
              channelKey,
              username,
              messages,
            ),
          ),
        ],
      ),
    );
  }

  // Visualização Direta do Chat (quando NÃO há transmissão ativa)
  Widget _buildDirectChatView(
    BuildContext context,
    bool isDark,
    String activeChannelName,
    String channelKey,
    String username,
    List<_ChatMessage> messages,
  ) {
    return Container(
      color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      child: Column(
        children: [
          // Channel Header Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141520) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.hash, size: 18, color: _selectedAccentColor),
                const SizedBox(width: 10),
                Text(
                  activeChannelName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Canal Híbrido · Texto, Voz e Transmissão integrados',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const Spacer(),

                // Transmitir Tela Button
                ElevatedButton.icon(
                  onPressed: _toggleTransmission,
                  icon: const Icon(LucideIcons.screenShare, size: 14),
                  label: const Text(
                    'Transmitir Tela',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAccentColor,
                    foregroundColor: _selectedAccentColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // Message Feed or Clean Empty State
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.messageSquare,
                            size: 32,
                            color: _selectedAccentColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Início do canal #$activeChannelName',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Envie uma mensagem ou inicie uma transmissão para conversar!',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _toggleTransmission,
                          icon: const Icon(LucideIcons.screenShare, size: 14),
                          label: const Text('Iniciar Transmissão de Tela'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _selectedAccentColor,
                            side: BorderSide(color: _selectedAccentColor),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: msg.authorColor.withValues(alpha: 0.3),
                              child: Text(
                                msg.author.isNotEmpty ? msg.author[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: msg.authorColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        msg.author,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: msg.authorColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    msg.content,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Message Input Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141520) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Conversar em #$activeChannelName...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(channelKey, username),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.send, size: 16, color: _selectedAccentColor),
                    onPressed: () => _sendMessage(channelKey, username),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Palco de Transmissão Imersiva
  Widget _buildImmersiveStreamPlayer(bool isDark, String username) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090A10),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Graphic Simulation of Screen Share / Stream
          const CustomPaint(
            painter: _RacingStreamCanvasPainter(),
          ),

          // Screen Share Overlay
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selectedAccentColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.screenShare, size: 48, color: _selectedAccentColor),
                      const SizedBox(height: 12),
                      Text(
                        'Transmissão ao vivo de $username',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Transmissão de tela em alta fidelidade ativa',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Gradient Overlays
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Barra Inferior da Transmissão
  Widget _buildStageBottomControlBar(bool isDark, String username) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Live Indicator Badge
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFEF4444),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AO VIVO',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$username — Transmissão de Tela',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          // Stop Transmission Button
          ElevatedButton.icon(
            onPressed: _toggleTransmission,
            icon: const Icon(LucideIcons.screenShareOff, size: 12),
            label: const Text('Parar Transmissão', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),

          const SizedBox(width: 12),

          // Volume Control
          IconButton(
            icon: Icon(
              _streamVolume == 0 ? LucideIcons.volumeX : LucideIcons.volume2,
              size: 16,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _streamVolume = _streamVolume == 0 ? 0.75 : 0;
              });
            },
          ),
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 3,
                activeTrackColor: _selectedAccentColor,
                inactiveTrackColor: Colors.white24,
                thumbColor: _selectedAccentColor,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _streamVolume,
                onChanged: (val) => setState(() => _streamVolume = val),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Fullscreen Toggle
          IconButton(
            icon: Icon(
              _isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
              size: 16,
              color: Colors.white70,
            ),
            tooltip: 'Tela Cheia',
            onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
          ),
        ],
      ),
    );
  }

  // Floating Glassmorphism Chat HUD
  Widget _buildFloatingChatHud(
    BuildContext context,
    bool isDark,
    String activeChannelName,
    String channelKey,
    String username,
    List<_ChatMessage> messages,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141520).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF313244).withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HUD Header (Chat title + minimize button)
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF262838),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.messageSquare, size: 13, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Chat: #$activeChannelName',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _isChatMinimized = !_isChatMinimized),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _isChatMinimized ? LucideIcons.maximize2 : LucideIcons.minimize2,
                          size: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!_isChatMinimized) ...[
                // 2. Message Stream
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhuma mensagem ainda.\nEnvie algo no chat!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${msg.author}: ',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: msg.authorColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: msg.content,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 3. Message Input Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1018),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF262838)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Mensagem em #$activeChannelName',
                              hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onSubmitted: (_) => _sendMessage(channelKey, username),
                          ),
                        ),
                        InkWell(
                          onTap: () => _sendMessage(channelKey, username),
                          borderRadius: BorderRadius.circular(4),
                          child: const Icon(LucideIcons.send, size: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Quick Voice Control Bar inside HUD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10111A),
                    border: Border(top: BorderSide(color: Color(0xFF1E2030))),
                  ),
                  child: Row(
                    children: [
                      // Mic toggle
                      InkWell(
                        onTap: () => setState(() => _isMicMuted = !_isMicMuted),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isMicMuted
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _isMicMuted ? LucideIcons.micOff : LucideIcons.mic,
                            size: 14,
                            color: _isMicMuted ? const Color(0xFFEF4444) : Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Headphones toggle
                      InkWell(
                        onTap: () => setState(() => _isDeafened = !_isDeafened),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            _isDeafened ? LucideIcons.headphones : LucideIcons.headphones,
                            size: 14,
                            color: _isDeafened ? const Color(0xFFEF4444) : Colors.white70,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Sair Button (Red Pill)
                      ElevatedButton.icon(
                        onPressed: _leaveVoice,
                        icon: const Icon(LucideIcons.logOut, size: 11),
                        label: const Text('Sair', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SERVER HOME VIEW (BANNER + RESUMO + ATIVIDADES)
  // ===========================================================================
  Widget _buildServerHomeContent(
    BuildContext context,
    bool isDark,
    String username,
    List<ChannelModel> channels,
  ) {
    final memberCount = widget.server.memberCount < 1 ? 1 : widget.server.memberCount;

    return Container(
      color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            _buildServerHeroBanner(isDark),

            const SizedBox(height: 24),

            // Activity + Media Listening Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildActivityCard(isDark, channels),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildMediaListeningCard(isDark),
                      const SizedBox(height: 16),
                      _buildCommunitySummaryCard(isDark, memberCount),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Announcements and Server Details
            _buildAnnouncementsAndRulesSection(isDark),
          ],
        ),
      ),
    );
  }

  // Server Hero Banner
  Widget _buildServerHeroBanner(bool isDark) {
    final currentGradient = _bannerPresets[_selectedBannerPreset];
    final memberCount = widget.server.memberCount < 1 ? 1 : widget.server.memberCount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedAccentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedAccentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Top
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(15),
                bottom: _isCustomizingBanner ? Radius.zero : const Radius.circular(15),
              ),
              gradient: LinearGradient(
                colors: currentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    LucideIcons.gamepad2,
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Server Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _selectedAccentColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.gamepad2,
                            size: 30,
                            color: _selectedAccentColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Server Name & Category
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.server.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.server.category} · $memberCount ${memberCount == 1 ? "membro" : "membros"}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Personalizar Button
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _isCustomizingBanner = !_isCustomizingBanner),
                        icon: Icon(
                          _isCustomizingBanner ? LucideIcons.x : LucideIcons.slidersHorizontal,
                          size: 14,
                        ),
                        label: Text(
                          _isCustomizingBanner ? 'Fechar' : 'Personalizar',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF181926).withValues(alpha: 0.85),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customization Drawer
          if (_isCustomizingBanner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141520),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Banner',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(_bannerPresets.length, (idx) {
                    final preset = _bannerPresets[idx];
                    final isSelected = _selectedBannerPreset == idx;
                    return InkWell(
                      onTap: () => setState(() => _selectedBannerPreset = idx),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 32,
                        height: 22,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: preset,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(width: 16),
                  Text(
                    'Cor',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  ..._accentPalette.map((color) {
                    final isSelected = _selectedAccentColor.toARGB32() == color.toARGB32();
                    return InkWell(
                      onTap: () => setState(() => _selectedAccentColor = color),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(serversControllerProvider.notifier).updateServerCustomization(
                        widget.server.id,
                        bannerPreset: _selectedBannerPreset,
                        accentColor: _selectedAccentColor.toARGB32(),
                      );
                      if (mounted) {
                        setState(() => _isCustomizingBanner = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 2),
                            backgroundColor: _selectedAccentColor,
                            content: Text(
                              'Personalização do servidor salva!',
                              style: TextStyle(
                                color: _selectedAccentColor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAccentColor,
                      foregroundColor: _selectedAccentColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Salvar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Activity Card
  Widget _buildActivityCard(bool isDark, List<ChannelModel> channels) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acontecendo no servidor',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'As novidades mais recentes da comunidade',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (channels.isNotEmpty)
                ElevatedButton(
                  onPressed: () => _openHybridChannel(channels.first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAccentColor,
                    foregroundColor: _selectedAccentColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Abrir canal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),

          const SizedBox(height: 16),

          _buildActivityItem(
            isDark: isDark,
            icon: LucideIcons.bell,
            title: 'Boas-vindas ao servidor ${widget.server.name}!',
            subtitle: 'Comunidade pronta · Canais híbridos integrados',
            time: 'Hoje',
          ),
          const SizedBox(height: 10),
          _buildActivityItem(
            isDark: isDark,
            icon: LucideIcons.headphones,
            title: 'Canal #${channels.isNotEmpty ? channels.first.name : "geral"} pronto',
            subtitle: _isTransmitting
                ? 'Transmissão de tela ativa no canal'
                : 'Conecte-se para conversar por texto, voz ou transmitir sua tela',
            time: _isTransmitting ? 'Ao Vivo' : 'Ativo',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161724) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _selectedAccentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaListeningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10281C) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.radio, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'CANAL HÍBRIDO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _isTransmitting ? LucideIcons.screenShare : LucideIcons.headphones,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTransmitting ? 'Transmissão Ativa' : 'Sala de Áudio e Texto',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _isTransmitting
                          ? 'Transmissão de tela ao vivo'
                          : 'Pronto para conversas e transmissões',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySummaryCard(bool isDark, int memberCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da comunidade',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$memberCount',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _selectedAccentColor,
                      ),
                    ),
                    Text(
                      memberCount == 1 ? 'membro' : 'membros',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isInVoice ? '1' : '0',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'em chamada',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsAndRulesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações do servidor',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1D2C) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.pin, size: 14, color: Color(0xFFF87171)),
                        const SizedBox(width: 6),
                        Text(
                          'Regras do Servidor',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Respeite todos os membros da comunidade. Sem spam e com foco em colaboração e respeito mútuo.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1D2C) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: _selectedAccentColor),
                        const SizedBox(width: 6),
                        Text(
                          'Canais Híbridos',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada canal combina chat de texto, chamada de áudio e transmissão de tela no mesmo ambiente integrado.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. RIGHT SIDEBAR (CANAIS | MEMBROS | RESUMO)
  // ===========================================================================
  Widget _buildRightSidebar(
    BuildContext context,
    bool isDark,
    List<ChannelModel> channels,
    String username,
  ) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFF8FAFC),
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header Tabs: Canais | Membros | Resumo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildSidebarTabButton(
                  title: 'Canais',
                  tab: ServerSidebarTab.canais,
                  icon: LucideIcons.volume2,
                  isDark: isDark,
                ),
                _buildSidebarTabButton(
                  title: 'Membros',
                  tab: ServerSidebarTab.membros,
                  icon: LucideIcons.users,
                  isDark: isDark,
                ),
                _buildSidebarTabButton(
                  title: 'Resumo',
                  tab: ServerSidebarTab.resumo,
                  icon: LucideIcons.barChart2,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: _buildSidebarTabContent(isDark, channels, username),
          ),

          // Bottom Voice Connection Status (Docked Footer)
          _buildDockedVoiceFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarTabButton({
    required String title,
    required ServerSidebarTab tab,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _activeSidebarTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeSidebarTab = tab),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2E8F0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? _selectedAccentColor
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarTabContent(
    bool isDark,
    List<ChannelModel> channels,
    String username,
  ) {
    switch (_activeSidebarTab) {
      case ServerSidebarTab.canais:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          children: [
            ...channels.map((c) {
              final isCurrentActive = _viewMode == ServerViewMode.channel && _activeChannel?.id == c.id;
              final isConnected = _isInVoice && _connectedVoiceChannelId == c.id;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: isCurrentActive
                      ? (isDark ? const Color(0xFF1E2030) : const Color(0xFFE2E8F0))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentActive
                        ? _selectedAccentColor.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel Item Header
                    InkWell(
                      onTap: () => _openHybridChannel(c),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.hash,
                              size: 14,
                              color: isCurrentActive ? _selectedAccentColor : (isDark ? Colors.white60 : Colors.black54),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isCurrentActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (isConnected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: const Text(
                                  '1',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Connected Real Members list under active channel
                    if (isConnected)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
                        child: _buildNestedMemberRow(
                          initials: username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          name: username,
                          color: _selectedAccentColor,
                          isLive: _isTransmitting,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );

      case ServerSidebarTab.membros:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'ONLINE — 1',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ),
            _buildSidebarMemberRow(username, 'Owner & Criador', _selectedAccentColor),
          ],
        );

      case ServerSidebarTab.resumo:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estatísticas',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                '• Canais Híbridos: ${channels.length}',
                style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                '• Membros Conectados: ${_isInVoice ? 1 : 0}',
                style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNestedMemberRow({
    required String initials,
    required String name,
    required Color color,
    required bool isLive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.2),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: const Text(
                'AO VIVO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarMemberRow(String name, String role, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  role,
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Docked Voice Footer at bottom right of sidebar
  Widget _buildDockedVoiceFooter(bool isDark) {
    if (!_isInVoice) {
      return const SizedBox.shrink();
    }
    final channelName = _connectedVoiceChannelId != null && _activeChannel != null
        ? _activeChannel!.name
        : 'geral';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10111A) : const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Conectado',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4ADE80),
                ),
              ),
              const Spacer(),
              Text(
                'Conexão estável',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$channelName · ${widget.server.name}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(_isMicMuted ? LucideIcons.micOff : LucideIcons.mic, size: 14),
                onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(_isDeafened ? LucideIcons.headphones : LucideIcons.headphones, size: 14),
                onPressed: () => setState(() => _isDeafened = !_isDeafened),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _leaveVoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
                child: const Text('Sair', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String author;
  final Color authorColor;
  final String content;
  final DateTime timestamp;

  const _ChatMessage({
    required this.author,
    required this.authorColor,
    required this.content,
    required this.timestamp,
  });
}

// Custom Painter for Immersive Simulation/Racing Video Stage
class _RacingStreamCanvasPainter extends CustomPainter {
  const _RacingStreamCanvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Asphalt Track Simulation
    final trackPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
          Color(0xFF020617),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trackPaint);

    // Speed Motion Lines
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.12)
      ..strokeWidth = 2;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, size.height * 0.4),
        Offset(i + 120, size.height * 0.9),
        linePaint,
      );
    }

    // Racing Kerb Red-White Strip
    final kerbPaint = Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.72, size.width, 16),
        const Radius.circular(4),
      ),
      kerbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
