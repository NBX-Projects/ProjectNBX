import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';

class CreateServerDialog extends ConsumerStatefulWidget {
  const CreateServerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateServerDialog(),
    );
  }

  @override
  ConsumerState<CreateServerDialog> createState() => _CreateServerDialogState();
}

class _CreateServerDialogState extends ConsumerState<CreateServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _joinCodeController = TextEditingController();
  bool _isJoinMode = false;
  bool _isPublic = false;
  String _selectedCategory = ServerModel.canonicalCategories.first;
  int _selectedBannerPreset = 0;
  Color _selectedAccentColor = const Color(0xFFF5CBA7);
  bool _isSubmitting = false;

  final List<String> _categories = ServerModel.canonicalCategories;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _joinCodeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconUrlController.dispose();
    _descriptionController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(serversControllerProvider.notifier)
        .joinServer(code);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text(
              'Você entrou no servidor com sucesso!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else {
        final error =
            ref.read(serversControllerProvider).error ??
            'Servidor não encontrado com o código fornecido.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkDanger
                : AppColors.lightDanger,
            content: Text(error),
          ),
        );
      }
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final strings = ref.read(stringsProvider);
    setState(() => _isSubmitting = true);
    final name = _nameController.text.trim();
    final iconUrl = _iconUrlController.text.trim();

    final success = await ref
        .read(serversControllerProvider.notifier)
        .createServer(
          name,
          iconUrl: iconUrl.isNotEmpty ? iconUrl : null,
          category: _selectedCategory,
          bannerPreset: _selectedBannerPreset,
          accentColor: _selectedAccentColor.toARGB32(),
          isPublic: _isPublic,
          description: _descriptionController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _selectedAccentColor,
            content: Text(
              strings.serverCreatedSuccess(name),
              style: GoogleFonts.inter(
                color: _selectedAccentColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else {
        final error =
            ref.read(serversControllerProvider).error ??
            'Erro ao criar servidor';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkDanger
                : AppColors.lightDanger,
            content: Text(error),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(stringsProvider);
    final currentGradient = AppColors.bannerPresets[_selectedBannerPreset];

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedAccentColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(
              LucideIcons.server,
              size: 20,
              color: _selectedAccentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isJoinMode
                  ? 'Entrar em um Servidor'
                  : strings.dialogCreateServerTitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Selector Tabs
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141520)
                      : const Color(0xFFE2E8F0),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF313244)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isJoinMode = false),
                        borderRadius: AppRadius.borderSm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isJoinMode
                                ? _selectedAccentColor
                                : Colors.transparent,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Center(
                            child: Text(
                              'Criar Novo',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: !_isJoinMode
                                    ? Colors.black
                                    : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isJoinMode = true),
                        borderRadius: AppRadius.borderSm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isJoinMode
                                ? _selectedAccentColor
                                : Colors.transparent,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Center(
                            child: Text(
                              'Entrar com Código',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isJoinMode
                                    ? Colors.black
                                    : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isJoinMode) ...[
                // Join Mode Form
                Text(
                  'CÓDIGO DE CONVITE OU ID DO SERVIDOR',
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
                TextField(
                  controller: _joinCodeController,
                  autofocus: true,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ex: srv_104e12aa-953b-4794-b5f2-7ce0190c64b9',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF141520)
                        : const Color(0xFFFFFFFF),
                    prefixIcon: const Icon(LucideIcons.keyRound, size: 16),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMd,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF313244)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleJoin(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cole aqui o código fornecido pelo criador do servidor (no PC ou por outro usuário) para participar instantaneamente.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Live Banner & Identity Preview Card
                      Container(
                        height: 84,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.borderMd,
                          gradient: LinearGradient(
                            colors: currentGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: _selectedAccentColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _selectedAccentColor.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Icon(
                                LucideIcons.gamepad2,
                                size: 76,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _selectedAccentColor,
                                      borderRadius: AppRadius.borderSm,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.server,
                                        size: 22,
                                        color:
                                            _selectedAccentColor
                                                    .computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nameController.text.trim().isEmpty
                                              ? 'Nome do Servidor'
                                              : _nameController.text.trim(),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.45,
                                            ),
                                            borderRadius: AppRadius.borderXs,
                                          ),
                                          child: Text(
                                            '${_selectedCategory.toUpperCase()} · 1 MEMBRO',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 9,
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
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Server Name Field
                      Text(
                        strings.serverNameLabel,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        style: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: strings.serverNamePlaceholder,
                          hintStyle: GoogleFonts.inter(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkInput
                              : AppColors.lightCanvas,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: BorderSide(
                              color: _selectedAccentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return strings.serverNameRequired;
                          }
                          if (val.trim().length < 2) {
                            return strings.serverNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Category Selector
                      Text(
                        'CATEGORIA DO SERVIDOR',
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            mouseCursor: SystemMouseCursors.click,
                            borderRadius: AppRadius.borderSm,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _selectedAccentColor
                                    : (isDark
                                          ? AppColors.darkInput
                                          : AppColors.lightCanvas),
                                borderRadius: AppRadius.borderSm,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (_selectedAccentColor
                                                    .computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white)
                                      : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Server Visibility (Public vs Private)
                      Text(
                        'VISIBILIDADE DO SERVIDOR',
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
                            child: InkWell(
                              onTap: () => setState(() => _isPublic = false),
                              borderRadius: AppRadius.borderMd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isPublic
                                      ? (isDark
                                          ? const Color(0xFF232538)
                                          : const Color(0xFFE2E8F0))
                                      : (isDark
                                          ? AppColors.darkInput
                                          : AppColors.lightCanvas),
                                  borderRadius: AppRadius.borderMd,
                                  border: Border.all(
                                    color: !_isPublic
                                        ? _selectedAccentColor
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                    width: !_isPublic ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.lock,
                                      size: 16,
                                      color: !_isPublic
                                          ? _selectedAccentColor
                                          : (isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Privado',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Apenas por convite direto',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
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
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isPublic = true),
                              borderRadius: AppRadius.borderMd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _isPublic
                                      ? (isDark
                                          ? const Color(0xFF232538)
                                          : const Color(0xFFE2E8F0))
                                      : (isDark
                                          ? AppColors.darkInput
                                          : AppColors.lightCanvas),
                                  borderRadius: AppRadius.borderMd,
                                  border: Border.all(
                                    color: _isPublic
                                        ? _selectedAccentColor
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                    width: _isPublic ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.globe,
                                      size: 16,
                                      color: _isPublic
                                          ? _selectedAccentColor
                                          : (isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Público',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Listado no Hub para explorar',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Server Description
                      Text(
                        'DESCRIÇÃO / BIO (OPCIONAL)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Sobre o que é este servidor? Descreva para quem for entrar...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkInput
                              : AppColors.lightCanvas,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: BorderSide(
                              color: _selectedAccentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Banner & Accent Customization Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141520)
                              : const Color(0xFFF1F5F9),
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner Gradient Selector
                            Text(
                              'PERSONALIZAÇÃO INICIAL',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Banner',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ...List.generate(
                                  AppColors.bannerPresets.length,
                                  (idx) {
                                    final preset = AppColors.bannerPresets[idx];
                                    final isSelected =
                                        _selectedBannerPreset == idx;
                                    return InkWell(
                                      onTap: () => setState(
                                        () => _selectedBannerPreset = idx,
                                      ),
                                      mouseCursor: SystemMouseCursors.click,
                                      borderRadius: AppRadius.borderSm,
                                      child: Container(
                                        width: 28,
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
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.transparent,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: preset.first
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 4,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Accent Color Palette
                            Row(
                              children: [
                                Text(
                                  'Cor',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 26),
                                ...AppColors.serverAccentPalette.map((color) {
                                  final isSelected =
                                      _selectedAccentColor.toARGB32() ==
                                      color.toARGB32();
                                  return InkWell(
                                    onTap: () => setState(
                                      () => _selectedAccentColor = color,
                                    ),
                                    mouseCursor: SystemMouseCursors.click,
                                    borderRadius: AppRadius.borderPill,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: color.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  blurRadius: 6,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Icon URL Field (Optional)
                      Text(
                        strings.serverIconLabel,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _iconUrlController,
                        style: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkInput
                              : AppColors.lightCanvas,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.borderMd,
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
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
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            strings.cancel,
            style: GoogleFonts.inter(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAccentColor,
            foregroundColor: _selectedAccentColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderPill,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          onPressed: _isSubmitting
              ? null
              : (_isJoinMode ? _handleJoin : _handleCreate),
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _selectedAccentColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                )
              : Text(
                  _isJoinMode ? 'Entrar no Servidor' : strings.createServer,
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
        ),
      ],
    );
  }
}
