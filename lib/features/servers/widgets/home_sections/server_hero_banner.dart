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

  const ServerHeroBanner({
    super.key,
    required this.server,
    this.isMobile = false,
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
  bool _isHoveringBanner = false;
  bool _isSavingIcon = false;
  late final TextEditingController _iconUrlController;

  @override
  void initState() {
    super.initState();
    _iconUrlController = TextEditingController(text: widget.server.iconUrl ?? '');
  }

  @override
  void didUpdateWidget(covariant ServerHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id) {
      _iconUrlController.text = widget.server.iconUrl ?? '';
    } else if (oldWidget.server.iconUrl != widget.server.iconUrl && !_isSavingIcon) {
      _iconUrlController.text = widget.server.iconUrl ?? '';
    }
  }

  @override
  void dispose() {
    _iconUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveServerIcon() async {
    final newUrl = _iconUrlController.text.trim();
    setState(() => _isSavingIcon = true);
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
    setState(() => _isSavingIcon = true);
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

  @override
  Widget build(BuildContext context) {
    final currentGradient = widget.bannerPresets[widget.selectedBannerPreset];

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
                    horizontal: widget.isMobile ? 12 : 16,
                    vertical: widget.isMobile ? 10 : 12,
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
                      _buildServerIcon(widget.isMobile),
                      const SizedBox(width: 12),
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
                                      fontSize: widget.isMobile ? 16 : 18,
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
                                    widget.server.category.isEmpty
                                        ? 'Geral'
                                        : widget.server.category,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.memberCount} ${widget.memberCount == 1 ? "membro" : "membros"}',
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
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: (widget.isMobile ||
                            _isHoveringBanner ||
                            widget.isCustomizingBanner)
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
            if (widget.isCustomizingBanner) _buildCustomizationDrawer(widget.isMobile),
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
                    hintStyle:
                        GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderSm),
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
              if (widget.server.iconUrl != null &&
                  widget.server.iconUrl!.isNotEmpty) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _isSavingIcon ? null : _removeServerIcon,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  child: const Text('Remover', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 10),
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
}
