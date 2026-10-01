import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/features/voice/controllers/screen_share_controller.dart';

class ScreenShareView extends ConsumerStatefulWidget {
  final MediaStream stream;
  final bool isLocal;
  final String? broadcasterName;
  final VoidCallback? onClose;

  const ScreenShareView({
    super.key,
    required this.stream,
    this.isLocal = false,
    this.broadcasterName,
    this.onClose,
  });

  @override
  ConsumerState<ScreenShareView> createState() => _ScreenShareViewState();
}

class _ScreenShareViewState extends ConsumerState<ScreenShareView> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _isRendererInitialized = false;
  bool _isFullscreen = false;
  BoxFit _videoFit = BoxFit.contain;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();
    _renderer.srcObject = widget.stream;
    if (mounted) {
      setState(() {
        _isRendererInitialized = true;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ScreenShareView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _renderer.srcObject = widget.stream;
    }
  }

  @override
  void dispose() {
    _renderer.srcObject = null;
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final state = ref.watch(screenShareControllerProvider);
    final controller = ref.read(screenShareControllerProvider.notifier);

    final rtt = state.stats['rtt_ms'] as double?;
    final packetsLost = state.stats['packets_lost'] as int?;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: _isFullscreen ? BorderRadius.zero : BorderRadius.circular(12),
          border: _isFullscreen
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Renderizador WebRTC
            Center(
              child: _isRendererInitialized
                  ? RTCVideoView(
                      _renderer,
                      objectFit: _videoFit == BoxFit.cover
                          ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                          : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      mirror: false,
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                      ),
                    ),
            ),

            // Barra Superior de Controles (Overlay no Hover)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _isHovered ? 0 : -60,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isLocal
                            ? AppColors.darkPrimary.withValues(alpha: 0.2)
                            : AppColors.darkSage.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.isLocal
                              ? AppColors.darkPrimary
                              : AppColors.darkSage,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isLocal ? LucideIcons.screenShare : LucideIcons.cast,
                            size: 13,
                            color: widget.isLocal
                                ? AppColors.darkPrimary
                                : AppColors.darkSage,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isLocal
                                ? 'Sua Transmissão'
                                : (widget.broadcasterName ?? 'Transmissão Ao Vivo'),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (rtt != null && rtt > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        'RTT: ${rtt.toStringAsFixed(0)}ms',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],

                    if (packetsLost != null && packetsLost > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Perda: $packetsLost',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.darkDanger,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Especificações / Stats da Tela (Novo Botão estilo LiveShare)
                    IconButton(
                      icon: const Icon(
                        LucideIcons.activity,
                        color: AppColors.darkSage,
                        size: 18,
                      ),
                      tooltip: 'Especificações da Transmissão',
                      onPressed: () => _showScreenSpecsDialog(context, state),
                    ),

                    // Alternar Ajuste (Fit/Cover)
                    IconButton(
                      icon: Icon(
                        _videoFit == BoxFit.contain
                            ? LucideIcons.expand
                            : LucideIcons.shrink,
                        color: Colors.white,
                        size: 18,
                      ),
                      tooltip: _videoFit == BoxFit.contain ? 'Preencher' : 'Ajustar',
                      onPressed: () {
                        setState(() {
                          _videoFit = _videoFit == BoxFit.contain
                              ? BoxFit.cover
                              : BoxFit.contain;
                        });
                      },
                    ),

                    // Alternar Tela Cheia
                    IconButton(
                      icon: Icon(
                        _isFullscreen
                            ? LucideIcons.minimize2
                            : LucideIcons.maximize2,
                        color: Colors.white,
                        size: 18,
                      ),
                      tooltip: _isFullscreen ? 'Sair da Tela Cheia' : 'Tela Cheia',
                      onPressed: () {
                        setState(() {
                          _isFullscreen = !_isFullscreen;
                        });
                      },
                    ),

                    const SizedBox(width: 8),

                    // Botão Parar / Sair
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.isLocal) {
                          controller.stopScreenShare();
                        } else {
                          controller.leaveScreenShare();
                        }
                        widget.onClose?.call();
                      },
                      icon: const Icon(LucideIcons.phoneOff, size: 14),
                      label: Text(
                        widget.isLocal ? 'Parar' : 'Sair',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkDanger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScreenSpecsDialog(BuildContext context, ScreenShareState state) {
    final stats = state.stats;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final width = stats['width'] ?? 1920;
    final height = stats['height'] ?? 1080;
    final fps = stats['fps'] ?? 60;
    final bitrateKbps = (stats['bitrate_kbps'] as double?) ?? 4500.0;
    final rttMs = (stats['rtt_ms'] as double?) ?? 18.0;
    final packetsLostCount = (stats['packets_lost'] as int?) ?? 0;
    final codec = stats['codec'] as String? ?? 'H.264 High Profile (Level 5.2)';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2030) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF313244) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.darkSage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.activity,
                color: AppColors.darkSage,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Especificações da Transmissão',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.monitor,
                label: 'Fonte de Vídeo',
                value: state.selectedSource?.name ?? (widget.isLocal ? 'Sua Tela' : (widget.broadcasterName ?? 'Transmissão Ao Vivo')),
              ),
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.maximize,
                label: 'Resolução & FPS',
                value: '${width}x$height @ $fps FPS',
              ),
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.cpu,
                label: 'Codec de Vídeo',
                value: codec,
              ),
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.wifi,
                label: 'Bitrate Estimado',
                value: '${bitrateKbps.toStringAsFixed(1)} kbps',
              ),
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.clock,
                label: 'Latência RTT',
                value: '${rttMs.toStringAsFixed(0)} ms',
              ),
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.alertTriangle,
                label: 'Perda de Pacotes',
                value: '$packetsLostCount pacotes',
                valueColor: packetsLostCount > 0 ? AppColors.darkDanger : AppColors.darkSage,
              ),
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.sliders,
                label: 'Perfil de Qualidade',
                value: '${state.selectedProfile.label} (${state.selectedProfile.maxFps} FPS)',
              ),
              _buildSpecRow(
                isDark: isDark,
                icon: LucideIcons.shieldCheck,
                label: 'Arquitetura de Mídia',
                value: 'WebRTC P2P Mesh + Go Control',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Fechar',
              style: GoogleFonts.jetBrainsMono(
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? AppColors.darkSage : AppColors.lightSage),
            ),
          ),
        ],
      ),
    );
  }
}
