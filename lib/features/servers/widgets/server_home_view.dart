import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/servers/models/channel_model.dart';
import 'package:justtalking/features/servers/models/server_join_request_model.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:justtalking/features/servers/models/server_role_model.dart';
import 'package:justtalking/features/servers/widgets/home_sections/server_active_call_banner.dart';
import 'package:justtalking/features/servers/widgets/home_sections/server_hero_banner.dart';
import 'package:justtalking/features/servers/widgets/home_sections/server_pending_requests_card.dart';
import 'package:justtalking/features/servers/widgets/home_sections/server_roles_card.dart';
import 'package:justtalking/features/voice/models/voice_participant_info.dart';

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
  List<ServerJoinRequestModel> _pendingRequests = [];
  List<Map<String, dynamic>> _members = [];
  List<ServerRoleModel> _roles = [];

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
          _pendingRequests = results[2] as List<ServerJoinRequestModel>;
        });
      }
    } catch (_) {
      // Ignorar falhas silenciosamente ao carregar dados opcionais
    }
  }

  bool get _canManageRoles {
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    if (currentUserId == null) return false;
    if (currentUserId == widget.server.ownerId) return true;

    for (final m in _members) {
      final uid =
          m['user_id'] as String? ??
          (m['user'] as Map<String, dynamic>?)?['id'] as String?;
      if (uid == currentUserId) {
        final roles = m['roles'] as List<dynamic>? ?? [];
        for (final r in roles) {
          if (r is Map) {
            final perms = r['permissions'] as Map<String, dynamic>? ?? {};
            if (perms['can_manage_roles'] == true) return true;
          } else if (r is ServerRoleModel && r.canManageRoles) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool get _canAcceptJoinRequests {
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    if (currentUserId == null) return false;
    if (currentUserId == widget.server.ownerId) return true;

    for (final m in _members) {
      final uid =
          m['user_id'] as String? ??
          (m['user'] as Map<String, dynamic>?)?['id'] as String?;
      if (uid == currentUserId) {
        final roles = m['roles'] as List<dynamic>? ?? [];
        for (final r in roles) {
          if (r is Map) {
            final perms = r['permissions'] as Map<String, dynamic>? ?? {};
            if (perms['can_accept_join_requests'] == true) return true;
          } else if (r is ServerRoleModel && r.canAcceptJoinRequests) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _acceptRequest(ServerJoinRequestModel req) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final success = await apiClient.reviewJoinRequest(
        widget.server.id,
        req.id,
        approve: true,
      );
      if (success) {
        await _loadExtraData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${req.userName ?? 'Usuário'} foi aceito no servidor!',
              ),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar pedido: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(ServerJoinRequestModel req) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final success = await apiClient.reviewJoinRequest(
        widget.server.id,
        req.id,
        approve: false,
      );
      if (success) {
        await _loadExtraData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido de ${req.userName ?? 'Usuário'} recusado.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao recusar pedido: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    final isTablet = screenWidth >= 768 && screenWidth <= 1024;
    final isMobileOrTablet = screenWidth <= 1024;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final memberCount = _members.isNotEmpty
        ? _members.length
        : (widget.server.memberCount < 1 ? 1 : widget.server.memberCount);

    return Container(
      color: widget.isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobileOrTablet ? 0 : 20,
          0,
          isMobileOrTablet ? 0 : 20,
          isMobile ? (bottomInset > 0 ? bottomInset + 16.0 : 20.0) : 20.0,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Banner com Personalização, Badges e Paleta (100% width no mobile e tablet)
                  ServerHeroBanner(
                    server: widget.server,
                    isMobile: isMobile,
                    isDark: widget.isDark,
                    selectedBannerPreset: widget.selectedBannerPreset,
                    selectedAccentColor: widget.selectedAccentColor,
                    bannerPresets: widget.bannerPresets,
                    accentPalette: widget.accentPalette,
                    isCustomizingBanner: widget.isCustomizingBanner,
                    onToggleCustomizeBanner: widget.onToggleCustomizeBanner,
                    onSelectBannerPreset: widget.onSelectBannerPreset,
                    onSelectAccentColor: widget.onSelectAccentColor,
                    onSaveCustomization: widget.onSaveCustomization,
                    memberCount: memberCount,
                  ),

                  const SizedBox(height: 14),

                  // Cards e Seções de Conteúdo (com margem lateral no mobile e tablet)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : (isTablet ? 16 : 0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Chamada Ativa (quando houver pessoas em voz ao vivo)
                        if (totalMembersInCall > 0) ...[
                          ServerActiveCallBanner(
                            isMobile: isMobile,
                            isDark: widget.isDark,
                            channels: widget.channels,
                            voiceParticipants: widget.voiceParticipants,
                            connectedVoiceChannelId:
                                widget.connectedVoiceChannelId,
                            onOpenChannel: widget.onOpenChannel,
                            onJoinVoice: widget.onJoinVoice,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Pedidos de Entrada Pendentes
                        if (_canAcceptJoinRequests &&
                            _pendingRequests.isNotEmpty) ...[
                          ServerPendingRequestsCard(
                            isMobile: isMobile,
                            isDark: widget.isDark,
                            server: widget.server,
                            pendingRequests: _pendingRequests,
                            onRequestsChanged: _loadExtraData,
                            onAcceptRequest: _acceptRequest,
                            onRejectRequest: _rejectRequest,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Cargos do Servidor (exibido para administradores com permissão de gerenciamento)
                        if (_canManageRoles) ...[
                          ServerRolesCard(
                            isMobile: isMobile,
                            isDark: widget.isDark,
                            server: widget.server,
                            roles: _roles,
                            selectedAccentColor: widget.selectedAccentColor,
                            onRolesUpdated: _loadExtraData,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
