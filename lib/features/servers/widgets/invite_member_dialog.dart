import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';

class InviteMemberDialog extends ConsumerStatefulWidget {
  final ServerModel server;
  final VoidCallback? onMembersUpdated;

  const InviteMemberDialog({
    super.key,
    required this.server,
    this.onMembersUpdated,
  });

  static Future<void> show(
    BuildContext context,
    ServerModel server, {
    VoidCallback? onMembersUpdated,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => InviteMemberDialog(
        server: server,
        onMembersUpdated: onMembersUpdated,
      ),
    );
  }

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  bool _isCopied = false;
  String? _errorMessage;
  String? _successMessage;

  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;

  bool _isLoadingInvites = true;
  bool _isGeneratingInvite = false;
  String? _latestGeneratedCode;
  bool _showSettings = false;

  int _selectedExpirySeconds = 86400; // 24h
  int _selectedMaxUses = 0; // unlimited

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadInvites();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final rawMembers = await apiClient.getServerMembers(widget.server.id);
      if (mounted) {
        setState(() {
          _members = rawMembers;
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  Future<void> _loadInvites() async {
    setState(() => _isLoadingInvites = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final rawInvites = await apiClient.getServerInvites(widget.server.id);
      if (mounted) {
        final validInvites = rawInvites
            .where(
              (inv) => inv['is_expired'] != true && inv['is_exhausted'] != true,
            )
            .toList();

        setState(() {
          if (validInvites.isNotEmpty) {
            _latestGeneratedCode = validInvites.first['code']?.toString();
            _isLoadingInvites = false;
          }
        });

        // Se não houver convite ativo, gera automaticamente um código curto de 24h
        if (validInvites.isEmpty) {
          await _generateInvite(autoCopy: false);
        } else {
          setState(() => _isLoadingInvites = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInvites = false);
      }
    }
  }

  Future<void> _generateInvite({bool autoCopy = true}) async {
    setState(() => _isGeneratingInvite = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.createInvite(
        widget.server.id,
        maxAgeSeconds: _selectedExpirySeconds > 0
            ? _selectedExpirySeconds
            : null,
        maxUses: _selectedMaxUses > 0 ? _selectedMaxUses : null,
      );
      if (res != null && res['code'] != null) {
        final newCode = res['code'].toString();
        setState(() {
          _latestGeneratedCode = newCode;
        });
        if (autoCopy) {
          await _copyInviteCode(code: newCode);
        }
      }
      if (mounted) {
        setState(() => _isGeneratingInvite = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingInvite = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _copyInviteCode({String? code}) async {
    final textToCopy = code ?? _latestGeneratedCode ?? '';
    if (textToCopy.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      setState(() => _isCopied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isCopied = false);
      });
    }
  }

  Future<void> _handleAddMember() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Digite o nome de usuário ou e-mail.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final isEmail = text.contains('@');
      await apiClient.addServerMember(
        widget.server.id,
        email: isEmail ? text : null,
        username: !isEmail ? text : null,
      );

      _inputController.clear();
      await _loadMembers();
      widget.onMembersUpdated?.call();
      ref.read(serversControllerProvider.notifier).loadServers();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Membro adicionado com sucesso ao servidor!';
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _successMessage = null;
        });
      }
    }
  }

  Future<void> _handleRemoveMember(String userId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.removeServerMember(widget.server.id, userId);
      await _loadMembers();
      widget.onMembersUpdated?.call();
      ref.read(serversControllerProvider.notifier).loadServers();
    } catch (_) {}
  }

  Widget _buildChipBadge({
    required String label,
    required Color color,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor ?? color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<T>(
            isExpanded: true,
            initialValue: value,
            dropdownColor: isDark ? const Color(0xFF1E2030) : Colors.white,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E2030) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF313244)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Color(widget.server.accentColor);
    final currentUser = ref.watch(authControllerProvider).user;
    final isOwner =
        currentUser != null && currentUser.id == widget.server.ownerId;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF313244) : const Color(0xFFCBD5E1),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181926) : const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF282A3A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.userPlus,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Convidar para ${widget.server.name}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Adicione amigos ou compartilhe o código de convite',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                children: [
                  // 1. Unified Short Invite Code Box
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LINK DE CONVITE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      _buildChipBadge(
                        label: 'Código Curto (Base62)',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141520)
                          : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF313244)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              _isLoadingInvites && _latestGeneratedCode == null
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Gerando código seguro...',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : SelectableText(
                                  _latestGeneratedCode ?? 'Gerando...',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _latestGeneratedCode == null
                              ? null
                              : () => _copyInviteCode(),
                          icon: Icon(
                            _isCopied ? LucideIcons.check : LucideIcons.copy,
                            size: 14,
                            color: _isCopied
                                ? const Color(0xFF10B981)
                                : Colors.black,
                          ),
                          label: Text(
                            _isCopied ? 'Copiado!' : 'Copiar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isCopied
                                  ? const Color(0xFF10B981)
                                  : Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCopied
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15)
                                : accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Seu link de convite é temporário.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            setState(() => _showSettings = !_showSettings),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showSettings
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.settings2,
                                size: 12,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showSettings
                                    ? 'Ocultar opções'
                                    : 'Editar validade do link',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Configurações Expansíveis de Expiração e Usos do Convite
                  if (_showSettings) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF141520)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF282A3A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.sliders,
                                size: 13,
                                color: AppColors.darkPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'CONFIGURAR NOVO CONVITE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildDropdownField<int>(
                                label: 'Expira em',
                                value: _selectedExpirySeconds,
                                items: const [
                                  DropdownMenuItem(
                                    value: 1800,
                                    child: Text('30 minutos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 3600,
                                    child: Text('1 hora'),
                                  ),
                                  DropdownMenuItem(
                                    value: 21600,
                                    child: Text('6 horas'),
                                  ),
                                  DropdownMenuItem(
                                    value: 86400,
                                    child: Text('24 horas (1 dia)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 604800,
                                    child: Text('7 dias'),
                                  ),
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Text('Nunca expira'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(
                                      () => _selectedExpirySeconds = val,
                                    );
                                  }
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _buildDropdownField<int>(
                                label: 'Usos Máximos',
                                value: _selectedMaxUses,
                                items: const [
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Text('Sem limite'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text('1 uso'),
                                  ),
                                  DropdownMenuItem(
                                    value: 5,
                                    child: Text('5 usos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 10,
                                    child: Text('10 usos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 25,
                                    child: Text('25 usos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 50,
                                    child: Text('50 usos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 100,
                                    child: Text('100 usos'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedMaxUses = val);
                                  }
                                },
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isGeneratingInvite
                                  ? null
                                  : () => _generateInvite(autoCopy: true),
                              icon: _isGeneratingInvite
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                      ),
                                    )
                                  : const Icon(LucideIcons.sparkles, size: 14),
                              label: Text(
                                _isGeneratingInvite
                                    ? 'Gerando...'
                                    : 'Gerar Novo Código',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF313244)
                                      : const Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Direct Add Input
                  Text(
                    'ADICIONAR POR USUÁRIO OU E-MAIL',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: darklord_mobile ou mobile@nbx.com',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF141520)
                                : const Color(0xFFFFFFFF),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: BorderSide(
                                color: accentColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _handleAddMember(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleAddMember,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Adicionar',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_successMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.checkCircle2,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 3. Current Members List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MEMBROS DO SERVIDOR (${_members.length})',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      if (_isLoadingMembers)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141520)
                          : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF313244)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: _members.isEmpty && !_isLoadingMembers
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Nenhum membro encontrado além do criador.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: isDark
                                  ? const Color(0xFF282A3A)
                                  : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) => _buildMemberTile(
                              member: _members[index],
                              isDark: isDark,
                              accentColor: accentColor,
                              isOwner: isOwner,
                            ),
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

  Widget _buildMemberTile({
    required Map<String, dynamic> member,
    required bool isDark,
    required Color accentColor,
    required bool isOwner,
  }) {
    final user = member['user'] as Map<String, dynamic>? ?? {};
    final String uName = (user['username'] ?? 'Usuário').toString();
    final String role = (member['role'] ?? 'member').toString();
    final bool isUserOwner = role == 'owner';
    final String mUserId = (member['user_id'] ?? '').toString();
    final email = user['email']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isUserOwner
                ? accentColor
                : (isDark ? const Color(0xFF282A3A) : const Color(0xFFE2E8F0)),
            child: Text(
              uName.isNotEmpty ? uName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isUserOwner
                    ? Colors.black
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uName,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (email != null && email.isNotEmpty)
                  Text(
                    email,
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
          _buildChipBadge(
            label: isUserOwner ? '👑 Dono' : 'Membro',
            color: isUserOwner
                ? accentColor
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            bgColor: isUserOwner
                ? accentColor.withValues(alpha: 0.2)
                : (isDark ? const Color(0xFF1E2030) : const Color(0xFFF1F5F9)),
            borderColor: isUserOwner
                ? accentColor.withValues(alpha: 0.4)
                : (isDark ? const Color(0xFF313244) : const Color(0xFFCBD5E1)),
          ),
          if (isOwner && !isUserOwner) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.userMinus, size: 14),
              color: const Color(0xFFEF4444),
              tooltip: 'Remover do Servidor',
              onPressed: () => _handleRemoveMember(mUserId),
            ),
          ],
        ],
      ),
    );
  }
}
