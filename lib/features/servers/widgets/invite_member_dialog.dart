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

  @override
  void initState() {
    super.initState();
    _loadMembers();
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

  Future<void> _copyInviteCode() async {
    await Clipboard.setData(ClipboardData(text: widget.server.id));
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Color(widget.server.accentColor);
    final currentUser = ref.watch(authControllerProvider).user;
    final isOwner = currentUser != null && currentUser.id == widget.server.ownerId;

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
                    color: isDark ? const Color(0xFF282A3A) : const Color(0xFFE2E8F0),
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
                      border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Icon(LucideIcons.userPlus, size: 18, color: accentColor),
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
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Adicione amigos ou compartilhe o código de convite',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                  // 1. Invite Code Box
                  Text(
                    'CÓDIGO DE CONVITE DO SERVIDOR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141520) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF313244) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            widget.server.id,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _copyInviteCode,
                          icon: Icon(
                            _isCopied ? LucideIcons.check : LucideIcons.copy,
                            size: 14,
                            color: _isCopied ? const Color(0xFF10B981) : Colors.black,
                          ),
                          label: Text(
                            _isCopied ? 'Copiado!' : 'Copiar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isCopied ? const Color(0xFF10B981) : Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCopied
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : accentColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No celular, basta colar este código na opção "Entrar em Servidor".',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Direct Add Input
                  Text(
                    'ADICIONAR POR USUÁRIO OU E-MAIL',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: darklord_mobile ou mobile@nbx.com',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF141520) : const Color(0xFFFFFFFF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF313244) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF313244) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: accentColor, width: 1.5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.plus, size: 16, color: Colors.black),
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
                        const Icon(LucideIcons.alertCircle, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_successMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF10B981)),
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
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                      color: isDark ? const Color(0xFF141520) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
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
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                              color: isDark ? const Color(0xFF282A3A) : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final m = _members[index];
                              final user = m['user'] as Map<String, dynamic>? ?? {};
                              final String uName = (user['username'] ?? 'Usuário').toString();
                              final String role = (m['role'] ?? 'member').toString();
                              final bool isUserOwner = role == 'owner';
                              final String mUserId = (m['user_id'] ?? '').toString();

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isUserOwner
                                            ? accentColor
                                            : (isDark ? const Color(0xFF282A3A) : const Color(0xFFE2E8F0)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          uName.isNotEmpty ? uName[0].toUpperCase() : 'U',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isUserOwner ? Colors.black : (isDark ? Colors.white : Colors.black87),
                                          ),
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
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          if (user['email'] != null && user['email'].toString().isNotEmpty)
                                            Text(
                                              user['email'].toString(),
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isUserOwner
                                            ? accentColor.withValues(alpha: 0.2)
                                            : (isDark ? const Color(0xFF1E2030) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isUserOwner
                                              ? accentColor.withValues(alpha: 0.4)
                                              : (isDark ? const Color(0xFF313244) : const Color(0xFFCBD5E1)),
                                        ),
                                      ),
                                      child: Text(
                                        isUserOwner ? '👑 Dono' : 'Membro',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: isUserOwner
                                              ? accentColor
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                        ),
                                      ),
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
                            },
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
}
