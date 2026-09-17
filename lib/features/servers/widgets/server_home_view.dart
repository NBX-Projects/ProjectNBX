import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
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
  List<ServerJoinRequestModel> _pendingRequests = [];
  List<Map<String, dynamic>> _members = [];
  List<ServerRoleModel> _roles = [];
  bool _isLoadingData = true;
  bool _isHoveringBanner = false;
  bool _isSavingIcon = false;
  late final TextEditingController _iconUrlController;

  @override
  void initState() {
    super.initState();
    _iconUrlController = TextEditingController(text: widget.server.iconUrl ?? '');
    _loadExtraData();
  }

  @override
  void didUpdateWidget(covariant ServerHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id) {
      _iconUrlController.text = widget.server.iconUrl ?? '';
      _loadExtraData();
    } else if (oldWidget.server.iconUrl != widget.server.iconUrl && !_isSavingIcon) {
      _iconUrlController.text = widget.server.iconUrl ?? '';
    }
  }

  @override
  void dispose() {
    _iconUrlController.dispose();
    super.dispose();
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
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  bool get _canManageRoles {
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    if (currentUserId == null) return false;
    if (currentUserId == widget.server.ownerId) return true;

    for (final m in _members) {
      final uid = m['user_id'] as String? ?? (m['user'] as Map<String, dynamic>?)?['id'] as String?;
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
      final uid = m['user_id'] as String? ?? (m['user'] as Map<String, dynamic>?)?['id'] as String?;
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

  String _getMemberDisplayName(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>? ?? {};
    final name = (user['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = (user['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    final directName = (m['name'] as String?)?.trim();
    if (directName != null && directName.isNotEmpty) return directName;
    final directUsername = (m['username'] as String?)?.trim();
    if (directUsername != null && directUsername.isNotEmpty) return directUsername;
    final email = (user['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Membro';
  }

  String? _getMemberUsername(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>? ?? {};
    final username = (user['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    final directUsername = (m['username'] as String?)?.trim();
    if (directUsername != null && directUsername.isNotEmpty) return directUsername;
    return null;
  }

  String? _getMemberAvatarUrl(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>? ?? {};
    final avatar = (user['avatar_url'] as String?)?.trim() ?? (m['avatar_url'] as String?)?.trim();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  Future<void> _saveServerIcon() async {
    final newUrl = _iconUrlController.text.trim();
    setState(() => _isSavingIcon = true);
    try {
      await ref.read(serversControllerProvider.notifier).updateServer(
        widget.server.id,
        iconUrl: newUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto do servidor atualizada com sucesso!'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar foto: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingIcon = false);
    }
  }

  Future<void> _removeServerIcon() async {
    setState(() => _isSavingIcon = true);
    try {
      await ref.read(serversControllerProvider.notifier).updateServer(
        widget.server.id,
        iconUrl: '',
      );
      _iconUrlController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto do servidor removida!'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover foto: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingIcon = false);
    }
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
              content: Text('${req.userName ?? 'Usuário'} foi aceito no servidor!'),
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: widget.isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 20,
          isMobile ? 12 : 16,
          isMobile ? 12 : 20,
          isMobile ? (bottomInset > 0 ? bottomInset + 16.0 : 20.0) : 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner Compacto com Edição via Hover
            _buildServerHeroBanner(context, isMobile: isMobile),

            const SizedBox(height: 14),

            // Chamada Ativa (quando houver pessoas em voz ao vivo)
            if (totalMembersInCall > 0) ...[
              _buildActiveCallBanner(context, isMobile: isMobile),
              const SizedBox(height: 14),
            ],

            // Card de Pedidos de Entrada (Apenas se o usuário puder aceitar E houver pedidos)
            if (_canAcceptJoinRequests && _pendingRequests.isNotEmpty) ...[
              _buildPendingRequestsCard(isMobile: isMobile),
              const SizedBox(height: 14),
            ],

            // Informações do Servidor & Lista Real de Membros & Cargos
            if (isMobile) ...[
              _buildServerMembersCard(isMobile: true),
              const SizedBox(height: 14),
              if (_canManageRoles) ...[
                _buildServerRolesCard(isMobile: true),
                const SizedBox(height: 14),
              ],
              _buildServerInfoCard(isMobile: true),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildServerMembersCard(isMobile: false),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_canManageRoles) ...[
                          _buildServerRolesCard(isMobile: false),
                          const SizedBox(height: 14),
                        ],
                        _buildServerInfoCard(isMobile: false),
                      ],
                    ),
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringBanner = true),
      onExit: (_) => setState(() => _isHoveringBanner = false),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: widget.selectedAccentColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.selectedAccentColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 10 : 12,
                  ),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Foto Real do Servidor (Tamanho reduzido)
                      _buildServerIcon(isMobile),
                      const SizedBox(width: 12),

                      // Título, Categoria e Badges Inline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.server.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildVisibilityBadge(widget.server.isPublic),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    widget.server.category.isEmpty ? 'Geral' : widget.server.category,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$memberCount ${memberCount == 1 ? "membro" : "membros"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.server.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.server.description,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Espaço para o botão flutuante de edição
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                // Botão de Edição discreto no canto superior direito (apenas no hover ou mobile)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: (isMobile || _isHoveringBanner || widget.isCustomizingBanner)
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(9999),
                      child: InkWell(
                        onTap: widget.onToggleCustomizeBanner,
                        borderRadius: BorderRadius.circular(9999),
                        child: Tooltip(
                          message: widget.isCustomizingBanner
                              ? 'Fechar personalização'
                              : 'Personalizar banner e foto',
                          child: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Icon(
                              widget.isCustomizingBanner
                                  ? LucideIcons.x
                                  : LucideIcons.pencil,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Drawer de Customização do Banner e Foto
            if (widget.isCustomizingBanner) _buildCustomizationDrawer(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildServerIcon(bool isMobile) {
    final size = isMobile ? 40.0 : 46.0;
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
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            size: 10,
            color: isPublic ? const Color(0xFFA8C5B5) : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Público' : 'Privado',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isPublic ? const Color(0xFFA8C5B5) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationDrawer(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141520),
        borderRadius: AppRadius.bottomLgInset,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha de Foto do Servidor
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: Colors.white24),
                  color: Colors.black26,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.borderSm,
                  child: _iconUrlController.text.trim().isNotEmpty
                      ? Image.network(
                          _iconUrlController.text.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            LucideIcons.image,
                            size: 16,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(
                          LucideIcons.image,
                          size: 16,
                          color: Colors.white54,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _iconUrlController,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'URL da imagem do servidor (https://...)',
                    hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(color: widget.selectedAccentColor),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSavingIcon ? null : _saveServerIcon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.selectedAccentColor,
                  foregroundColor: widget.selectedAccentColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                ),
                child: _isSavingIcon
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Salvar Foto',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
              ),
              if (widget.server.iconUrl != null && widget.server.iconUrl!.isNotEmpty) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _isSavingIcon ? null : _removeServerIcon,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  child: const Text('Remover', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 10),

          // Linha de Presets de Gradiente e Cores
          SingleChildScrollView(
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
                const SizedBox(width: 8),
                ...List.generate(widget.bannerPresets.length, (idx) {
                  final preset = widget.bannerPresets[idx];
                  final isSelected = widget.selectedBannerPreset == idx;
                  return InkWell(
                    onTap: () => widget.onSelectBannerPreset(idx),
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: AppRadius.borderSm,
                    child: Container(
                      width: 26,
                      height: 18,
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
                const SizedBox(width: 12),
                Text(
                  'Acento',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                ...widget.accentPalette.map((color) {
                  final isSelected =
                      widget.selectedAccentColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () => widget.onSelectAccentColor(color),
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: AppRadius.borderPill,
                    child: Container(
                      width: 18,
                      height: 18,
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
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: widget.onSaveCustomization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.selectedAccentColor,
                    foregroundColor:
                        widget.selectedAccentColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderSm,
                    ),
                  ),
                  child: const Text(
                    'Salvar Cores',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
      padding: EdgeInsets.all(isMobile ? 12 : 14),
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
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              borderRadius: AppRadius.borderMd,
            ),
            child: const Icon(LucideIcons.phoneCall, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'CHAMADA AO VIVO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF22C55E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${callChannel.name}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  activeCallParticipants.map((p) => p.username).join(', '),
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
          const SizedBox(width: 10),
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
              size: 13,
            ),
            label: Text(
              isUserInCall ? 'Entrar no Canal' : 'Conectar Áudio',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsCard({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1B231F) : const Color(0xFFF0FDF4),
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
          width: 1.5,
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
                  const Icon(
                    LucideIcons.userCheck,
                    size: 16,
                    color: Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PEDIDOS DE ENTRADA PENDENTES (${_pendingRequests.length})',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => ServerJoinRequestsDialog.show(
                  context,
                  widget.server,
                  onRequestsChanged: _loadExtraData,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF22C55E),
                ),
                child: Text(
                  'Ver Todos',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingRequests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final req = _pendingRequests[index];
              final displayName = req.userName ?? 'Usuário';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF141520)
                      : Colors.white,
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
                      radius: 13,
                      backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.2),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (req.message.isNotEmpty)
                            Text(
                              req.message,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: widget.isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botão Recusar
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 14, color: Colors.redAccent),
                      tooltip: 'Recusar pedido',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => _rejectRequest(req),
                    ),
                    const SizedBox(width: 4),
                    // Botão Aceitar
                    ElevatedButton(
                      onPressed: () => _acceptRequest(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check, size: 12, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            'Aceitar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget _buildServerRolesCard({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
              Row(
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 15,
                    color: widget.selectedAccentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CARGOS DO SERVIDOR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: widget.isDark
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
                color: widget.selectedAccentColor,
                onPressed: () => ServerRolesDialog.show(
                  context,
                  widget.server,
                  onRolesUpdated: _loadExtraData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_roles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum cargo personalizado criado.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: widget.isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _roles.map((r) {
                final roleColor = Color(r.color);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildServerMembersCard({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                '${_members.length} membros',
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
          const SizedBox(height: 12),

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
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final m = _members[index];
                final user = m['user'] as Map<String, dynamic>? ?? {};
                final userId = m['user_id'] as String? ?? user['id'] as String? ?? '';
                final displayName = _getMemberDisplayName(m);
                final username = _getMemberUsername(m);
                final avatarUrl = _getMemberAvatarUrl(m);
                final isOwner = userId == widget.server.ownerId;
                final rawRoles = m['roles'] as List<dynamic>? ?? [];

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                      // Avatar com Foto real ou inicial com fallback
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.selectedAccentColor.withValues(alpha: 0.2),
                          border: Border.all(
                            color: widget.selectedAccentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: widget.selectedAccentColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: widget.selectedAccentColor,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (username != null && username != displayName) ...[
                              const SizedBox(width: 6),
                              Text(
                                '@$username',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: widget.isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5CBA7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DONO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        name,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildServerInfoCard({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
          const SizedBox(height: 12),

          _buildInfoRow(
            LucideIcons.tag,
            'Categoria',
            widget.server.category.isEmpty ? 'Geral' : widget.server.category,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            widget.server.isPublic ? LucideIcons.globe : LucideIcons.lock,
            'Visibilidade',
            widget.server.isPublic ? 'Público' : 'Privado',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            LucideIcons.shield,
            'Cargos',
            '${_roles.length}',
          ),
          if (widget.server.isPublic) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              LucideIcons.userPlus,
              'Pedidos',
              _pendingRequests.isNotEmpty
                  ? '${_pendingRequests.length} pendente(s)'
                  : 'Nenhum',
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Botão rápido para Convidar Membro
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => InviteMemberDialog.show(
                context,
                widget.server,
                onMembersUpdated: _loadExtraData,
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
                foregroundColor: widget.selectedAccentColor,
                side: BorderSide(
                  color: widget.selectedAccentColor.withValues(alpha: 0.5),
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

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
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
              fontSize: 11.5,
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
              fontSize: 11.5,
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
