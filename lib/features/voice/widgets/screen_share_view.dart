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
}
