import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_join_request_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/models/server_role_model.dart';
import 'package:projectnbx/features/servers/widgets/invite_member_dialog.dart';
import 'package:projectnbx/features/servers/widgets/server_join_requests_dialog.dart';
import 'package:projectnbx/features/servers/widgets/server_roles_dialog.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';

class ServerHomeView extends ConsumerStatefulWidget {
  final ServerModel server;
  final bool isDark;
  final String username;
  final List<ChannelModel> channels;
  final bool isTransmitting;
  final int selectedBannerPreset;
  final ValueChanged<int> onSelectBannerPreset;
  final Color selectedAccentColor;
  final ValueChanged<Color> onSelectAccentColor;
  final bool isCustomizingBanner;
  final VoidCallback onToggleCustomizeBanner;
  final Future<void> Function() onSaveCustomization;
  final List<List<Color>> bannerPresets;
  final List<Color> accentPalette;
  final ValueChanged<ChannelModel> onOpenChannel;
  final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants;
  final String? clientSessionId;
  final String? connectedVoiceChannelId;
  final ValueChanged<ChannelModel>? onJoinVoice;
  final ValueChanged<VoiceParticipantInfo>? onWatchStream;
  final VoidCallback? onOpenInviteDialog;

  const ServerHomeView({
    super.key,
    required this.server,
    required this.isDark,
    required this.username,
    required this.channels,
    required this.isTransmitting,
    required this.selectedBannerPreset,
    required this.onSelectBannerPreset,
    required this.selectedAccentColor,
    required this.onSelectAccentColor,
    required this.isCustomizingBanner,
    required this.onToggleCustomizeBanner,
    required this.onSaveCustomization,
    this.bannerPresets = AppColors.bannerPresets,
    this.accentPalette = AppColors.serverAccentPalette,
    required this.onOpenChannel,
    this.voiceParticipants = const {},
    this.clientSessionId,
    this.connectedVoiceChannelId,
    this.onJoinVoice,
    this.onWatchStream,
    this.onOpenInviteDialog,
  });

  @override
  ConsumerState<ServerHomeView> createState() => _ServerHomeViewState();
}

class _ServerHomeViewState extends ConsumerState<ServerHomeView> {
  int _pendingRequestsCount = 0;
  List<Map<String, dynamic>> _members = [];
  List<ServerRoleModel> _roles = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadExtraData();
  }

  @override
  void didUpdateWidget(covariant ServerHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id) {
      _loadExtraData();
    }
  }

  Future<void> _loadExtraData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final membersFuture = apiClient.getServerMembers(widget.server.id);
      final rolesFuture = apiClient.getServerRoles(widget.server.id);
      final requestsFuture = widget.server.isPublic
          ? apiClient.getJoinRequests(widget.server.id, status: 'pending')
          : Future.value(<ServerJoinRequestModel>[]);

      final results = await Future.wait([
        membersFuture,
        rolesFuture,
        requestsFuture,
      ]);

      if (mounted) {
        setState(() {
          _members = results[0] as List<Map<String, dynamic>>;
          _roles = results[1] as List<ServerRoleModel>;
          _pendingRequestsCount = (results[2] as List).length;
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  int get totalMembersInCall {
    return widget.voiceParticipants.values.fold<int>(
      0,
      (sum, m) => sum + m.values.where((p) => p.isInVoice).length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: widget.isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 24,
          isMobile ? 14 : 20,
          isMobile ? 14 : 24,
          isMobile ? (bottomInset > 0 ? bottomInset + 20.0 : 24.0) : 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner com Foto Real do Servidor e Badges
            _buildServerHeroBanner(context, isMobile: isMobile),

            const SizedBox(height: 18),

            // Chamada Ativa (quando houver pessoas em voz ao vivo)
            if (totalMembersInCall > 0) ...[
              _buildActiveCallBanner(context, isMobile: isMobile),
              const SizedBox(height: 18),
            ],

            // Canais Híbridos do Servidor
            _buildChannelsSection(isMobile: isMobile),

            const SizedBox(height: 20),

            // Informações do Servidor & Lista Real de Membros ("Menos é mais")
            if (isMobile) ...[
              _buildServerInfoCard(isMobile: true),
              const SizedBox(height: 16),
              _buildServerMembersCard(isMobile: true),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildServerMembersCard(isMobile: false),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildServerInfoCard(isMobile: false),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerHeroBanner(BuildContext context, {bool isMobile = false}) {
    final currentGradient = widget.bannerPresets[widget.selectedBannerPreset];
    final memberCount = _members.isNotEmpty
        ? _members.length
        : (widget.server.memberCount < 1 ? 1 : widget.server.memberCount);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: widget.selectedAccentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.selectedAccentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: widget.isCustomizingBanner
                  ? AppRadius.topLg
                  : AppRadius.borderLgInset,
              gradient: LinearGradient(
                colors: currentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Foto Real do Servidor (Image.network com fallback elegante)
                    _buildServerIcon(isMobile),
                    const SizedBox(width: 14),

                    // Título, Badges e Categoria
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.server.name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildVisibilityBadge(widget.server.isPublic),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  widget.server.category,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$memberCount ${memberCount == 1 ? "membro" : "membros"}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botões de Ação Rápida
                    if (!isMobile) ...[
                      const SizedBox(width: 12),
                      _buildQuickActionButtons(),
                    ],
                  ],
                ),

                if (widget.server.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.server.description,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (isMobile) ...[
                  const SizedBox(height: 12),
                  _buildQuickActionButtons(isMobile: true),
                ],
              ],
            ),
          ),

          // Drawer de Customização do Banner
          if (widget.isCustomizingBanner) _buildCustomizationDrawer(isMobile),
        ],
      ),
    );
  }

  Widget _buildServerIcon(bool isMobile) {
    final size = isMobile ? 54.0 : 64.0;
    final hasIcon = widget.server.iconUrl != null &&
        widget.server.iconUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.selectedAccentColor,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderMd,
        child: hasIcon
            ? Image.network(
                widget.server.iconUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackIcon(size),
              )
            : _buildFallbackIcon(size),
      ),
    );
  }

  Widget _buildFallbackIcon(double size) {
    final name = widget.server.name.trim();
    if (name.isNotEmpty) {
      return Center(
        child: Text(
          name[0].toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
            color: widget.selectedAccentColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white,
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        LucideIcons.gamepad2,
        size: size * 0.45,
        color: widget.selectedAccentColor.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
      ),
    );
  }

  Widget _buildVisibilityBadge(bool isPublic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isPublic
            ? const Color(0xFFA8C5B5).withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: isPublic
              ? const Color(0xFFA8C5B5).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? LucideIcons.globe : LucideIcons.lock,
            size: 11,
            color: isPublic ? const Color(0xFFA8C5B5) : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Público' : 'Privado',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isPublic ? const Color(0xFFA8C5B5) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons({bool isMobile = false}) {
    final buttons = [
      // Botão Pedidos de Entrada (se público)
      if (widget.server.isPublic)
        ElevatedButton.icon(
          onPressed: () => ServerJoinRequestsDialog.show(
            context,
            widget.server,
            onRequestsChanged: _loadExtraData,
          ),
          icon: const Icon(LucideIcons.userCheck, size: 14),
          label: Text(
            _pendingRequestsCount > 0
                ? 'Pedidos ($_pendingRequestsCount)'
                : 'Pedidos',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _pendingRequestsCount > 0
                ? const Color(0xFF22C55E)
                : const Color(0xFF181926).withValues(alpha: 0.85),
            foregroundColor: _pendingRequestsCount > 0 ? Colors.black : Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),

      // Botão Cargos & Permissões
      ElevatedButton.icon(
        onPressed: () => ServerRolesDialog.show(
          context,
          widget.server,
          onRolesUpdated: _loadExtraData,
        ),
        icon: const Icon(LucideIcons.shieldCheck, size: 14),
        label: Text(
          'Cargos (${_roles.length})',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF181926).withValues(alpha: 0.85),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),

      // Botão Personalizar Banner
      ElevatedButton.icon(
        onPressed: widget.onToggleCustomizeBanner,
        icon: Icon(
          widget.isCustomizingBanner
              ? LucideIcons.x
              : LucideIcons.slidersHorizontal,
          size: 14,
        ),
        label: Text(
          widget.isCustomizingBanner ? 'Fechar' : 'Banner',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF181926).withValues(alpha: 0.85),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: buttons,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          buttons[i],
        ],
      ],
    );
  }

  Widget _buildCustomizationDrawer(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141520),
        borderRadius: AppRadius.bottomLgInset,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Banner',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 10),
            ...List.generate(widget.bannerPresets.length, (idx) {
              final preset = widget.bannerPresets[idx];
              final isSelected = widget.selectedBannerPreset == idx;
              return InkWell(
                onTap: () => widget.onSelectBannerPreset(idx),
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderSm,
                child: Container(
                  width: 30,
                  height: 20,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.borderSm,
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
            const SizedBox(width: 14),
            Text(
              'Cor',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 10),
            ...widget.accentPalette.map((color) {
              final isSelected =
                  widget.selectedAccentColor.toARGB32() == color.toARGB32();
              return InkWell(
                onTap: () => widget.onSelectAccentColor(color),
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderPill,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 6),
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
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: widget.onSaveCustomization,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.selectedAccentColor,
                foregroundColor:
                    widget.selectedAccentColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderSm,
                ),
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCallBanner(BuildContext context, {bool isMobile = false}) {
    ChannelModel? callChannel;
    List<VoiceParticipantInfo> activeCallParticipants = [];

    for (final ch in widget.channels) {
      final participants = widget.voiceParticipants[ch.id]?.values
              .where((p) => p.isInVoice)
              .toList() ??
          [];
      if (participants.isNotEmpty) {
        callChannel = ch;
        activeCallParticipants = participants;
        break;
      }
    }

    if (callChannel == null) return const SizedBox.shrink();

    final isUserInCall = widget.connectedVoiceChannelId == callChannel.id;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF10281C) : const Color(0xFFECFDF5),
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              borderRadius: AppRadius.borderMd,
            ),
            child: const Icon(LucideIcons.phoneCall, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'CHAMADA AO VIVO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF22C55E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${callChannel.name}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeCallParticipants.map((p) => p.username).join(', '),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              if (isUserInCall) {
                widget.onOpenChannel(callChannel!);
              } else {
                widget.onJoinVoice?.call(callChannel!);
              }
            },
            icon: Icon(
              isUserInCall ? LucideIcons.arrowRight : LucideIcons.phone,
              size: 14,
            ),
            label: Text(
              isUserInCall ? 'Entrar no Canal' : 'Conectar Áudio',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsSection({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CANAIS DO SERVIDOR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: widget.isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              Text(
                '${widget.channels.length} canais disponíveis',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: widget.isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.channels.map((ch) {
              final inVoice = widget.voiceParticipants[ch.id]?.values
                      .where((p) => p.isInVoice)
                      .length ??
                  0;

              return InkWell(
                onTap: () => widget.onOpenChannel(ch),
                borderRadius: AppRadius.borderMd,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF141520)
                        : const Color(0xFFF8FAFC),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: inVoice > 0
                          ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                          : (widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.hash,
                        size: 16,
                        color: inVoice > 0
                            ? const Color(0xFF22C55E)
                            : widget.selectedAccentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ch.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (inVoice > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF22C55E).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.phoneCall,
                                size: 10,
                                color: Color(0xFF22C55E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$inVoice',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServerMembersCard({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'MEMBROS DO SERVIDOR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: widget.isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.server.isPublic
                    ? '${_members.length} membros'
                    : 'Privado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: widget.isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Nenhum membro listado',
                  style: GoogleFonts.inter(
                    color: widget.isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final m = _members[index];
                final user = m['user'] as Map<String, dynamic>? ?? {};
                final userId = m['user_id'] as String? ?? user['id'] as String? ?? '';
                final userName = user['name'] as String? ?? user['username'] as String? ?? 'Membro';
                final isOwner = userId == widget.server.ownerId;
                final rawRoles = m['roles'] as List<dynamic>? ?? [];

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF141520)
                        : const Color(0xFFF8FAFC),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: widget.isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            widget.selectedAccentColor.withValues(alpha: 0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.selectedAccentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5CBA7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DONO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF5CBA7),
                            ),
                          ),
                        ),
                      ],
                      for (final r in rawRoles) ...[
                        const SizedBox(width: 6),
                        _buildRoleBadge(r),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(dynamic roleData) {
    String name = '';
    Color color = const Color(0xFFF5CBA7);

    if (roleData is Map) {
      name = roleData['name']?.toString() ?? '';
      final cVal = roleData['color'] as int?;
      if (cVal != null) color = Color(cVal);
    } else if (roleData is ServerRoleModel) {
      name = roleData.name;
      color = Color(roleData.color);
    }

    if (name.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        name,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildServerInfoCard({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
              color: widget.isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 14),

          _buildInfoRow(
            LucideIcons.tag,
            'Categoria',
            widget.server.category.isEmpty ? 'Geral' : widget.server.category,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            widget.server.isPublic ? LucideIcons.globe : LucideIcons.lock,
            'Visibilidade',
            widget.server.isPublic ? 'Público' : 'Privado',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            LucideIcons.shield,
            'Cargos',
            '${_roles.length}',
          ),
          if (widget.server.isPublic) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              LucideIcons.userPlus,
              'Pedidos',
              _pendingRequestsCount > 0
                  ? '$_pendingRequestsCount pendente(s)'
                  : 'Nenhum',
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Botão rápido para Convidar Membro
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => InviteMemberDialog.show(
                context,
                widget.server,
                onMembersUpdated: _loadExtraData,
              ),
              icon: const Icon(LucideIcons.userPlus, size: 15),
              label: Text(
                'Convidar Membro',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.selectedAccentColor,
                side: BorderSide(
                  color: widget.selectedAccentColor.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: widget.isDark
              ? AppColors.darkTextMuted
              : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: widget.isDark
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
