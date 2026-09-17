import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/models/server_role_model.dart';

class ServerRolesDialog extends ConsumerStatefulWidget {
  final ServerModel server;
  final VoidCallback? onRolesUpdated;

  const ServerRolesDialog({
    super.key,
    required this.server,
    this.onRolesUpdated,
  });

  static Future<void> show(
    BuildContext context,
    ServerModel server, {
    VoidCallback? onRolesUpdated,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => ServerRolesDialog(
        server: server,
        onRolesUpdated: onRolesUpdated,
      ),
    );
  }

  @override
  ConsumerState<ServerRolesDialog> createState() => _ServerRolesDialogState();
}

class _ServerRolesDialogState extends ConsumerState<ServerRolesDialog> {
  int _activeTab = 0; // 0 = Cargos, 1 = Membros
  bool _isLoading = true;
  List<ServerRoleModel> _roles = [];
  List<Map<String, dynamic>> _members = [];

  // Form para novo cargo / edição
  bool _isCreatingRole = false;
  ServerRoleModel? _editingRole;
  final TextEditingController _roleNameController = TextEditingController();
  int _selectedColor = 0xFFF5CBA7;
  bool _canAcceptJoinRequests = false;
  bool _canManageRoles = false;
  bool _isSavingRole = false;

  final List<int> _presetColors = [
    0xFFF5CBA7, // Peach
    0xFFA8C5B5, // Sage
    0xFFC5B4E3, // Lavender
    0xFFA5C4D4, // Powder Blue
    0xFFF9A8D4, // Pink
    0xFFFDE047, // Yellow
    0xFFFCA5A5, // Coral
    0xFF94A3B8, // Slate
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiClient = ref.read(apiClientProvider);
    try {
      final rolesFuture = apiClient.getServerRoles(widget.server.id);
      final membersFuture = apiClient.getServerMembers(widget.server.id);
      final results = await Future.wait([rolesFuture, membersFuture]);

      if (mounted) {
        setState(() {
          _roles = results[0] as List<ServerRoleModel>;
          _members = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCreateRole() {
    setState(() {
      _isCreatingRole = true;
      _editingRole = null;
      _roleNameController.clear();
      _selectedColor = 0xFFF5CBA7;
      _canAcceptJoinRequests = false;
      _canManageRoles = false;
    });
  }

  void _startEditRole(ServerRoleModel role) {
    setState(() {
      _isCreatingRole = true;
      _editingRole = role;
      _roleNameController.text = role.name;
      _selectedColor = role.color;
      _canAcceptJoinRequests = role.canAcceptJoinRequests;
      _canManageRoles = role.canManageRoles;
    });
  }

  void _cancelRoleForm() {
    setState(() {
      _isCreatingRole = false;
      _editingRole = null;
      _roleNameController.clear();
    });
  }

  Future<void> _saveRole() async {
    final name = _roleNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSavingRole = true);
    final apiClient = ref.read(apiClientProvider);

    try {
      final permissions = {
        'can_accept_join_requests': _canAcceptJoinRequests,
        'can_manage_roles': _canManageRoles,
      };

      if (_editingRole != null) {
        await apiClient.updateServerRole(
          widget.server.id,
          _editingRole!.id,
          name: name,
          color: _selectedColor,
          permissions: permissions,
        );
      } else {
        await apiClient.createServerRole(
          widget.server.id,
          name: name,
          color: _selectedColor,
          position: _roles.length + 1,
          permissions: permissions,
        );
      }

      widget.onRolesUpdated?.call();
      await _loadData();
      _cancelRoleForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingRole = false);
      }
    }
  }

  Future<void> _deleteRole(ServerRoleModel role) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.deleteServerRole(widget.server.id, role.id);
      widget.onRolesUpdated?.call();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _toggleMemberRole(
    String userId,
    ServerRoleModel role,
    bool isAssigned,
  ) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      if (isAssigned) {
        await apiClient.removeMemberRole(widget.server.id, userId, role.id);
      } else {
        await apiClient.assignMemberRole(widget.server.id, userId, role.id);
      }
      widget.onRolesUpdated?.call();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 620,
        height: 560,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            if (!_isCreatingRole) _buildTabs(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isCreatingRole
                      ? _buildRoleForm(isDark)
                      : (_activeTab == 0
                          ? _buildRolesList(isDark)
                          : _buildMembersRoleList(isDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5CBA7).withValues(alpha: 0.15),
              borderRadius: AppRadius.borderMd,
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 20,
              color: Color(0xFFF5CBA7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cargos & Permissões',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  widget.server.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              LucideIcons.x,
              size: 18,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141520) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Cargos (${_roles.length})', 0, isDark),
          const SizedBox(width: 8),
          _buildTabButton('Atribuir a Membros', 1, isDark),
          const Spacer(),
          if (_activeTab == 0)
            ElevatedButton.icon(
              onPressed: _startCreateRole,
              icon: const Icon(LucideIcons.plus, size: 14),
              label: Text(
                'Criar Cargo',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5CBA7),
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, bool isDark) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: AppRadius.borderSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E2030) : Colors.white)
              : Colors.transparent,
          borderRadius: AppRadius.borderSm,
          border: isSelected
              ? Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                )
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildRolesList(bool isDark) {
    if (_roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shieldAlert,
              size: 40,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum cargo criado',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crie cargos para delegar a moderação do servidor.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _roles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final role = _roles[index];
        final roleColor = Color(role.color);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141520) : const Color(0xFFF8FAFC),
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (role.canAcceptJoinRequests)
                          _buildPermissionChip(
                            'Aceitar Entradas',
                            const Color(0xFFA8C5B5),
                            isDark,
                          ),
                        if (role.canManageRoles)
                          _buildPermissionChip(
                            'Gerenciar Cargos',
                            const Color(0xFFC5B4E3),
                            isDark,
                          ),
                        if (!role.canAcceptJoinRequests && !role.canManageRoles)
                          Text(
                            'Sem permissões de moderação',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 16),
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                onPressed: () => _startEditRole(role),
                tooltip: 'Editar Cargo',
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 16),
                color: Colors.redAccent.withValues(alpha: 0.8),
                onPressed: () => _deleteRole(role),
                tooltip: 'Excluir Cargo',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRoleForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                onPressed: _cancelRoleForm,
                tooltip: 'Voltar',
              ),
              const SizedBox(width: 8),
              Text(
                _editingRole != null ? 'Editar Cargo' : 'Novo Cargo',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'NOME DO CARGO',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _roleNameController,
            autofocus: true,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Moderador, Líder, Membro VIP',
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkInput : AppColors.lightCanvas,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'COR DO CARGO',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors.map((colorVal) {
              final isSelected = _selectedColor == colorVal;
              return InkWell(
                onTap: () => setState(() => _selectedColor = colorVal),
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(colorVal),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(colorVal).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text(
            'PERMISSÕES ESPECÍFICAS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          _buildPermissionToggle(
            'Aceitar Pedidos de Entrada',
            'Permite aprovar ou recusar solicitações de novos membros para servidores públicos.',
            _canAcceptJoinRequests,
            (val) => setState(() => _canAcceptJoinRequests = val),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildPermissionToggle(
            'Gerenciar Cargos',
            'Permite criar, editar, excluir e atribuir cargos a outros membros.',
            _canManageRoles,
            (val) => setState(() => _canManageRoles = val),
            isDark,
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelRoleForm,
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSavingRole ? null : _saveRole,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5CBA7),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                child: _isSavingRole
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Salvar Cargo',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionToggle(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141520) : const Color(0xFFF8FAFC),
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFF5CBA7),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersRoleList(bool isDark) {
    if (_members.isEmpty) {
      return Center(
        child: Text(
          'Nenhum membro encontrado',
          style: GoogleFonts.inter(
            color: isDark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _members.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final memberData = _members[index];
        final user = memberData['user'] as Map<String, dynamic>? ?? {};
        final userId = memberData['user_id'] as String? ?? user['id'] as String? ?? '';
        final userName = user['name'] as String? ?? user['username'] as String? ?? 'Membro';
        final isOwner = userId == widget.server.ownerId;
        final rawRoles = memberData['roles'] as List<dynamic>? ?? [];
        final assignedRoleIds = rawRoles
            .map((r) => (r is Map ? r['id'] : r).toString())
            .toSet();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141520) : const Color(0xFFF8FAFC),
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF5CBA7).withValues(alpha: 0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFFF5CBA7),
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
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
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
                              'PROPRIETÁRIO',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF5CBA7),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_roles.isEmpty)
                      Text(
                        'Crie cargos primeiro para atribuir.',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _roles.map((role) {
                          final isAssigned = assignedRoleIds.contains(role.id);
                          final roleColor = Color(role.color);

                          return InkWell(
                            onTap: isOwner
                                ? null
                                : () => _toggleMemberRole(
                                      userId,
                                      role,
                                      isAssigned,
                                    ),
                            borderRadius: BorderRadius.circular(4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isAssigned
                                    ? roleColor.withValues(alpha: 0.2)
                                    : (isDark
                                        ? const Color(0xFF1E2030)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isAssigned
                                      ? roleColor
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: roleColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    role.name,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: isAssigned
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isAssigned
                                          ? roleColor
                                          : (isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted),
                                    ),
                                  ),
                                  if (isAssigned && !isOwner) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.check,
                                      size: 10,
                                      color: roleColor,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
