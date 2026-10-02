import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/servers/controllers/servers_controller.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ServerHeroBanner extends ConsumerStatefulWidget {
  final ServerModel server;
  final bool isMobile;
  final int selectedBannerPreset;
  final Color selectedAccentColor;
  final List<List<Color>> bannerPresets;
  final List<Color> accentPalette;
  final bool isCustomizingBanner;
  final VoidCallback onToggleCustomizeBanner;
  final ValueChanged<int> onSelectBannerPreset;
  final ValueChanged<Color> onSelectAccentColor;
  final Future<void> Function() onSaveCustomization;
  final int memberCount;
  final bool? isDark;

  const ServerHeroBanner({
    super.key,
    required this.server,
    this.isMobile = false,
    this.isDark,
    required this.selectedBannerPreset,
    required this.selectedAccentColor,
    this.bannerPresets = AppColors.bannerPresets,
    this.accentPalette = AppColors.serverAccentPalette,
    required this.isCustomizingBanner,
    required this.onToggleCustomizeBanner,
    required this.onSelectBannerPreset,
    required this.onSelectAccentColor,
    required this.onSaveCustomization,
    required this.memberCount,
  });

  @override
  ConsumerState<ServerHeroBanner> createState() => _ServerHeroBannerState();
}

class _ServerHeroBannerState extends ConsumerState<ServerHeroBanner> {
  bool _isSavingIcon = false;
  bool _isSavingBanner = false;
  late final TextEditingController _iconUrlController;
  late final TextEditingController _bannerUrlController;
  String? _localBannerUrl;
  String? _localIconUrl;

  @override
  void initState() {
    super.initState();
    _localBannerUrl = widget.server.bannerUrl;
    _localIconUrl = widget.server.iconUrl;
    _iconUrlController = TextEditingController(
      text: widget.server.iconUrl ?? '',
    );
    _bannerUrlController = TextEditingController(
      text: widget.server.bannerUrl ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ServerHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id) {
      _iconUrlController.text = widget.server.iconUrl ?? '';
      _bannerUrlController.text = widget.server.bannerUrl ?? '';
      _localBannerUrl = widget.server.bannerUrl;
      _localIconUrl = widget.server.iconUrl;
    } else {
      if (oldWidget.server.iconUrl != widget.server.iconUrl && !_isSavingIcon) {
        _iconUrlController.text = widget.server.iconUrl ?? '';
        _localIconUrl = widget.server.iconUrl;
      }
      if (oldWidget.server.bannerUrl != widget.server.bannerUrl &&
          !_isSavingBanner) {
        _bannerUrlController.text = widget.server.bannerUrl ?? '';
        _localBannerUrl = widget.server.bannerUrl;
      }
    }
  }

  @override
  void dispose() {
    _iconUrlController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveServerIcon() async {
    final newUrl = _iconUrlController.text.trim();
    setState(() {
      _isSavingIcon = true;
      _localIconUrl = newUrl;
    });
    try {
      await ref
          .read(serversControllerProvider.notifier)
          .updateServer(widget.server.id, iconUrl: newUrl);
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
    setState(() {
      _isSavingIcon = true;
      _localIconUrl = '';
    });
    try {
      await ref
          .read(serversControllerProvider.notifier)
          .updateServer(widget.server.id, iconUrl: '');
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

  Future<void> _saveServerBanner() async {
    final newUrl = _bannerUrlController.text.trim();
    setState(() {
      _isSavingBanner = true;
      _localBannerUrl = newUrl;
    });
    try {
      await ref
          .read(serversControllerProvider.notifier)
          .updateServer(widget.server.id, bannerUrl: newUrl);
      await ref
          .read(serversControllerProvider.notifier)
          .updateServerCustomization(widget.server.id, bannerUrl: newUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capa do servidor atualizada com sucesso!'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar capa: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBanner = false);
    }
  }

  Future<void> _removeServerBanner() async {
    setState(() {
      _isSavingBanner = true;
      _localBannerUrl = '';
    });
    try {
      await ref
          .read(serversControllerProvider.notifier)
          .updateServer(widget.server.id, bannerUrl: '');
      await ref
          .read(serversControllerProvider.notifier)
          .updateServerCustomization(widget.server.id, bannerUrl: '');
      _bannerUrlController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capa do servidor removida!'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover capa: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = widget.bannerPresets[widget.selectedBannerPreset];
    final serversState = ref.watch(serversControllerProvider);
    final liveServer =
        serversState.servers.cast<ServerModel?>().firstWhere(
          (s) => s?.id == widget.server.id,
          orElse: () => null,
        ) ??
        widget.server;

    final effectiveBannerUrl =
        (_localBannerUrl != null && _localBannerUrl!.isNotEmpty)
        ? _localBannerUrl
        : (liveServer.bannerUrl ?? widget.server.bannerUrl);

    final effectiveIconUrl =
        (_localIconUrl != null && _localIconUrl!.isNotEmpty)
        ? _localIconUrl
        : (liveServer.iconUrl ?? widget.server.iconUrl);

    final hasBanner =
        effectiveBannerUrl != null && effectiveBannerUrl.trim().isNotEmpty;
    final bannerHeight = widget.isMobile ? 180.0 : 250.0;

    final isDark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final canvasColor = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          ClipRRect(
            child: SizedBox(
              height: bannerHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Capa do Servidor (Imagem ou Gradiente Preset)
                  if (hasBanner)
                    Positioned.fill(
                      child: Image.network(
                        effectiveBannerUrl.trim(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildFallbackBanner(currentGradient),
                              Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            '[ServerHeroBanner] Erro ao carregar capa: $error',
                          );
                          return _buildFallbackBanner(currentGradient);
                        },
                      ),
                    )
                  else
                    Positioned.fill(
                      child: _buildFallbackBanner(currentGradient),
                    ),

                  // 2. Escurecimento geral cinematográfico
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),

                  // 3. Vignette lateral da esquerda para destacar ícone e nome do servidor
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.38, 0.75],
                        ),
                      ),
                    ),
                  ),

                  // 4. Fusão suave na base: o banner se junta ao fundo da aplicação ("desaparecer")
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            canvasColor.withValues(alpha: 0.0),
                            canvasColor.withValues(alpha: 0.0),
                            canvasColor.withValues(alpha: 0.35),
                            canvasColor.withValues(alpha: 0.75),
                            canvasColor,
                          ],
                          stops: const [0.0, 0.25, 0.58, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 4. Botão "Personalizar" no topo direito (estilo protótipo)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildCustomizeButton(),
                  ),

                  // 5. Bloco inferior esquerdo: Foto de Perfil + Nome + Categoria / Membros
                  Positioned(
                    left: widget.isMobile ? 12 : 18,
                    bottom: widget.isMobile ? 12 : 16,
                    right: widget.isMobile ? 12 : 18,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildServerIcon(
                          widget.isMobile,
                          effectiveIconUrl: effectiveIconUrl,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      liveServer.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: widget.isMobile ? 18 : 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildVisibilityBadge(liveServer.isPublic),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${liveServer.category.isEmpty ? "Gaming" : liveServer.category} · ${widget.memberCount} ${widget.memberCount == 1 ? "membro" : "membros"}',
                                style: GoogleFonts.inter(
                                  fontSize: widget.isMobile ? 11.5 : 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (liveServer.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  liveServer.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isCustomizingBanner)
            _buildCustomizationDrawer(widget.isMobile),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(List<Color> currentGradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildCustomizeButton() {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: widget.onToggleCustomizeBanner,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isCustomizingBanner ? LucideIcons.x : LucideIcons.wand2,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isCustomizingBanner ? 'Fechar' : 'Personalizar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerIcon(bool isMobile, {String? effectiveIconUrl}) {
    final size = isMobile ? 50.0 : 62.0;
    final icon = effectiveIconUrl ?? widget.server.iconUrl;
    final hasIcon = icon != null && icon.trim().isNotEmpty;
    final radius = BorderRadius.circular(isMobile ? 12 : 16);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.selectedAccentColor,
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
        child: hasIcon
            ? Image.network(
                icon.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackIcon(size),
              )
            : _buildFallbackIcon(size),
      ),
    );
  }

  Widget _buildFallbackIcon(double size) {
    return Center(
      child: Icon(LucideIcons.gamepad2, size: size * 0.52, color: Colors.white),
    );
  }

  Widget _buildVisibilityBadge(bool isPublic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPublic
            ? const Color(0xFFA8C5B5).withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.35),
        borderRadius: AppRadius.borderXs,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isEdgeToEdge = isMobile || screenWidth <= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141520),
        borderRadius: isEdgeToEdge ? BorderRadius.zero : AppRadius.bottomLgInset,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção 1: Capa do Servidor (Banner)
          Row(
            children: [
              const Icon(LucideIcons.image, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Capa do Servidor (Banner)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 46,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: Colors.white24),
                  color: Colors.black26,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.borderSm,
                  child: _bannerUrlController.text.trim().isNotEmpty
                      ? Image.network(
                          _bannerUrlController.text.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            LucideIcons.image,
                            size: 14,
                            color: Colors.white38,
                          ),
                        )
                      : const Icon(
                          LucideIcons.image,
                          size: 14,
                          color: Colors.white38,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _bannerUrlController,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'URL da imagem de capa (https://...)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
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
                onPressed: _isSavingBanner ? null : _saveServerBanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.selectedAccentColor,
                  foregroundColor:
                      widget.selectedAccentColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderSm,
                  ),
                ),
                child: _isSavingBanner
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Salvar Capa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (widget.server.bannerUrl != null &&
                  widget.server.bannerUrl!.isNotEmpty) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _isSavingBanner ? null : _removeServerBanner,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Remover', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Seção 2: Foto de Perfil (Ícone)
          Row(
            children: [
              const Icon(LucideIcons.user, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Foto do Servidor (Ícone)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                            LucideIcons.user,
                            size: 14,
                            color: Colors.white38,
                          ),
                        )
                      : const Icon(
                          LucideIcons.user,
                          size: 14,
                          color: Colors.white38,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _iconUrlController,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'URL da foto/ícone (https://...)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
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
                  foregroundColor:
                      widget.selectedAccentColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderSm,
                  ),
                ),
                child: _isSavingIcon
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Salvar Foto',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (widget.server.iconUrl != null &&
                  widget.server.iconUrl!.isNotEmpty) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _isSavingIcon ? null : _removeServerIcon,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Remover', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),

          // Seção 3: Cores e Gradientes (Fallback da Capa)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Gradiente Fallback',
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
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
