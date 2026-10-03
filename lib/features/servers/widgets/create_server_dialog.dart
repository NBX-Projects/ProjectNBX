import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/locale_controller.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/features/servers/controllers/servers_controller.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  bool _showAdvanced = false;
  String _selectedCategory = ServerModel.canonicalCategories.first;
  int _selectedBannerPreset = 0;
  Color _selectedAccentColor = const Color(0xFFF5CBA7);
  bool _isSubmitting = false;

  final List<String> _categories = ServerModel.canonicalCategories;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _iconUrlController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
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

  Color _getCategoryColor(String category, Color fallbackAccent) {
    final c = category.toUpperCase().trim();
    if (c.contains('GAMING') || c.contains('JOGO')) {
      return const Color(0xFF4F46E5);
    }
    if (c.contains('RACE') || c.contains('SIM') || c.contains('CORRIDA')) {
      return const Color(0xFFD97706);
    }
    if (c.contains('DEV') ||
        c.contains('PROG') ||
        c.contains('CODE') ||
        c.contains('TECH') ||
        c.contains('PROGRAMAÇÃO')) {
      return const Color(0xFF2563EB);
    }
    if (c.contains('ESTUDO') || c.contains('STUDY')) {
      return const Color(0xFF059669);
    }
    if (c.contains('FPS') || c.contains('CS2') || c.contains('VALORANT')) {
      return const Color(0xFFE11D48);
    }
    if (c.contains('MÚSICA') || c.contains('MUSIC')) {
      return const Color(0xFF7C3AED);
    }
    if (c.contains('DESIGN') || c.contains('ARTE')) {
      return const Color(0xFFDB2777);
    }
    if (c.contains('CRIPTO') || c.contains('FINAN')) {
      return const Color(0xFF10B981);
    }
    if (c.contains('COMUNIDADE') || c.contains('GERAL')) {
      return const Color(0xFF475569);
    }
    return fallbackAccent;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(stringsProvider);
    final currentGradient = AppColors.bannerPresets[_selectedBannerPreset];
    final categoryColor = _getCategoryColor(
      _selectedCategory,
      _selectedAccentColor,
    );
    final categoryTextColor = categoryColor.computeLuminance() > 0.45
        ? const Color(0xFF141520)
        : Colors.white;

    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final cardBgColor = isDark ? const Color(0xFF161724) : Colors.white;
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 580;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: isMobile ? screenSize.height * 0.92 : 640,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabeçalho Minimalista Responsivo
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 20,
                  isMobile ? 14 : 18,
                  isMobile ? 12 : 16,
                  isMobile ? 10 : 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _selectedAccentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LucideIcons.server,
                            size: 18,
                            color: _selectedAccentColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isJoinMode
                                    ? 'Entrar em um Servidor'
                                    : 'Criar seu Servidor',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _isJoinMode
                                    ? 'Informe o código para participar instantaneamente'
                                    : 'Configure o seu espaço para conversas e chamadas de voz',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
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
                        if (!isMobile) ...[
                          const SizedBox(width: 10),
                          _buildTabs(isDark),
                          const SizedBox(width: 6),
                        ],
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          tooltip: 'Fechar',
                          splashRadius: 18,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    if (isMobile) ...[
                      const SizedBox(height: 12),
                      _buildTabs(isDark, expanded: true),
                    ],
                  ],
                ),
              ),

              // 2. Conteúdo Principal Rolável (sem divisória superior)
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 20,
                    6,
                    isMobile ? 16 : 20,
                    10,
                  ),
                  child: _isJoinMode
                      ? _buildJoinModeContent(isDark)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth >= 580;
                            if (isDesktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Coluna Esquerda: Preview ao Vivo + Estilo
                                  SizedBox(
                                    width: 260,
                                    child: _buildPreviewAndStyleColumn(
                                      isDark,
                                      currentGradient,
                                      categoryColor,
                                      categoryTextColor,
                                      cardBgColor,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Coluna Direita: Formulário de Criação
                                  Expanded(
                                    child: _buildCreateForm(isDark, strings),
                                  ),
                                ],
                              );
                            }

                            // Layout Mobile: FORMULÁRIO PRIMEIRO
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCreateForm(isDark, strings),
                                const SizedBox(height: 18),
                                _buildPreviewAndStyleColumn(
                                  isDark,
                                  currentGradient,
                                  categoryColor,
                                  categoryTextColor,
                                  cardBgColor,
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),

              // 3. Rodapé com Ações (sem divisória inferior)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 20,
                  8,
                  isMobile ? 16 : 20,
                  isMobile ? 14 : 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        foregroundColor: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      child: Text(
                        strings.cancel,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAccentColor,
                        foregroundColor:
                            _selectedAccentColor.computeLuminance() > 0.5
                            ? const Color(0xFF181926)
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 11,
                        ),
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
                                color:
                                    _selectedAccentColor.computeLuminance() >
                                        0.5
                                    ? const Color(0xFF181926)
                                    : Colors.white,
                              ),
                            )
                          : Text(
                              _isJoinMode
                                  ? 'Entrar no Servidor'
                                  : 'Criar Servidor',
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark, {bool expanded = false}) {
    final tabs = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (expanded)
          Expanded(
            child: _buildTabButton(
              title: 'Criar',
              isActive: !_isJoinMode,
              isDark: isDark,
              onTap: () => setState(() => _isJoinMode = false),
            ),
          )
        else
          _buildTabButton(
            title: 'Criar',
            isActive: !_isJoinMode,
            isDark: isDark,
            onTap: () => setState(() => _isJoinMode = false),
          ),
        if (expanded)
          Expanded(
            child: _buildTabButton(
              title: 'Entrar',
              isActive: _isJoinMode,
              isDark: isDark,
              onTap: () => setState(() => _isJoinMode = true),
            ),
          )
        else
          _buildTabButton(
            title: 'Entrar',
            isActive: _isJoinMode,
            isDark: isDark,
            onTap: () => setState(() => _isJoinMode = true),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12131D) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isDark ? const Color(0xFF282A3E) : const Color(0xFFCBD5E1),
        ),
      ),
      child: tabs,
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _selectedAccentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isActive
                ? (_selectedAccentColor.computeLuminance() > 0.5
                      ? const Color(0xFF181926)
                      : Colors.white)
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinModeContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CÓDIGO DE CONVITE OU ID DO SERVIDOR',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
              borderRadius: BorderRadius.circular(8),
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
          'Cole aqui o código ou link fornecido por um amigo para entrar diretamente na comunidade.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewAndStyleColumn(
    bool isDark,
    List<Color> currentGradient,
    Color categoryColor,
    Color categoryTextColor,
    Color cardBgColor,
  ) {
    final bannerImg = _iconUrlController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LucideIcons.sparkles, size: 13, color: _selectedAccentColor),
            const SizedBox(width: 5),
            Text(
              'PRÉVIA NO HUB',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Card Fiel ao HubServerCard
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedAccentColor.withValues(
                alpha: isDark ? 0.35 : 0.25,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _selectedAccentColor.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner (114px)
              SizedBox(
                height: 114,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradiente ou Imagem
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    if (bannerImg.isNotEmpty)
                      Image.network(
                        bannerImg,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    // Escurecimento
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.20),
                      ),
                    ),
                    // Fusão na Base
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              cardBgColor.withValues(alpha: 0.0),
                              cardBgColor.withValues(alpha: 0.35),
                              cardBgColor.withValues(alpha: 0.85),
                              cardBgColor,
                            ],
                            stops: const [0.0, 0.40, 0.80, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Pill Categoria
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedCategory.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: categoryTextColor,
                          ),
                        ),
                      ),
                    ),
                    // Pill Visibilidade
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Icon(
                          _isPublic ? LucideIcons.globe : LucideIcons.lock,
                          size: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info do Servidor
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Nome do Servidor'
                          : _nameController.text.trim(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1 membro',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Pílula inferior
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedAccentColor.withValues(
                          alpha: isDark ? 0.08 : 0.05,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _selectedAccentColor.withValues(
                            alpha: isDark ? 0.22 : 0.18,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _descriptionController.text.trim().isNotEmpty
                                ? LucideIcons.activity
                                : LucideIcons.hash,
                            size: 12,
                            color: _selectedAccentColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _descriptionController.text.trim().isNotEmpty
                                  ? _descriptionController.text.trim()
                                  : 'Novo espaço no Just Talking',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _selectedAccentColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

        const SizedBox(height: 14),

        // Controles de Estilo Visual (Presets de Capa & Cores)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141520) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTILO VISUAL',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 8),
              // Linha com Presets de Capa
              Row(
                children: [
                  Text(
                    'Capa',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          AppColors.bannerPresets.length,
                          (idx) {
                            final preset = AppColors.bannerPresets[idx];
                            final isSelected = _selectedBannerPreset == idx;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedBannerPreset = idx),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: 24,
                                height: 18,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
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
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Linha com Cores de Acento
              Row(
                children: [
                  Text(
                    'Cor ',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AppColors.serverAccentPalette.map((color) {
                          final isSelected =
                              _selectedAccentColor.toARGB32() ==
                              color.toARGB32();
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedAccentColor = color),
                            child: Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm(bool isDark, dynamic strings) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nome do Servidor
          Text(
            'NOME DO SERVIDOR *',
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
            controller: _nameController,
            autofocus: true,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Squad Gamer ou Dev Lounge',
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
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
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _selectedAccentColor, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Informe um nome para o servidor';
              }
              if (val.trim().length < 2) {
                return 'O nome deve ter no mínimo 2 caracteres';
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // 2. Categoria
          Text(
            'CATEGORIA',
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
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedAccentColor
                        : (isDark
                              ? const Color(0xFF141520)
                              : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(6),
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
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? (_selectedAccentColor.computeLuminance() > 0.5
                                ? const Color(0xFF181926)
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

          // 3. Visibilidade (Privado vs Público)
          Text(
            'VISIBILIDADE',
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
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isPublic = false),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: !_isPublic
                          ? (isDark
                                ? const Color(0xFF232538)
                                : const Color(0xFFE2E8F0))
                          : (isDark
                                ? const Color(0xFF141520)
                                : const Color(0xFFFFFFFF)),
                      borderRadius: BorderRadius.circular(8),
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
                          size: 15,
                          color: !_isPublic
                              ? _selectedAccentColor
                              : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Apenas por convite',
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
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _isPublic
                          ? (isDark
                                ? const Color(0xFF232538)
                                : const Color(0xFFE2E8F0))
                          : (isDark
                                ? const Color(0xFF141520)
                                : const Color(0xFFFFFFFF)),
                      borderRadius: BorderRadius.circular(8),
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
                          size: 15,
                          color: _isPublic
                              ? _selectedAccentColor
                              : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Visível no Explorar',
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

          const SizedBox(height: 12),

          // 4. Seção Avançada Opcional (Accordion)
          InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Opções adicionais (descrição e capa)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showAdvanced) ...[
            const SizedBox(height: 8),
            // Descrição
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Descrição ou lema da comunidade...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF141520)
                    : const Color(0xFFFFFFFF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // URL da Capa Personalizada
            TextFormField(
              controller: _iconUrlController,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'URL da imagem de capa (https://...)',
                hintStyle: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF141520)
                    : const Color(0xFFFFFFFF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                prefixIcon: const Icon(LucideIcons.image, size: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
