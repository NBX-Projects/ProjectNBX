import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/features/voice/services/desktop_hardware_service.dart';

class ScreenShareConfig {
  final String title;
  final String type; // 'screen' | 'window'
  final String resolution; // '720p' | '1080p' | '1440p'
  final int fps; // 15 | 30 | 60
  final bool shareAudio;
  final String previewType;
  final String? thumbnail;
  final String? sourceId;

  const ScreenShareConfig({
    required this.title,
    required this.type,
    this.resolution = '1080p',
    this.fps = 60,
    this.shareAudio = true,
    this.previewType = 'nbx',
    this.thumbnail,
    this.sourceId,
  });
}

class ScreenShareDialog extends StatefulWidget {
  final Color accentColor;
  final String channelName;

  const ScreenShareDialog({
    super.key,
    required this.accentColor,
    required this.channelName,
  });

  static Future<ScreenShareConfig?> show(
    BuildContext context, {
    required Color accentColor,
    required String channelName,
  }) {
    return showDialog<ScreenShareConfig>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ScreenShareDialog(
        accentColor: accentColor,
        channelName: channelName,
      ),
    );
  }

  @override
  State<ScreenShareDialog> createState() => _ScreenShareDialogState();
}

class _ScreenShareDialogState extends State<ScreenShareDialog> {
  int _selectedTab = 0; // 0 = Telas, 1 = Janelas
  int _selectedSourceIndex = 0;

  String _selectedResolution = '1080p';
  int _selectedFps = 60;
  bool _shareAudio = true;
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();
  final DesktopHardwareService _hardwareService = const DesktopHardwareService();

  List<Map<String, dynamic>> _screens = [];
  List<Map<String, dynamic>> _windows = [];
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRealHardwareSources();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollSourcesSilently();
    });
  }

  Future<void> _pollSourcesSilently() async {
    if (!mounted || _isAutoRefreshing) return;
    _isAutoRefreshing = true;
    try {
      final all = await _hardwareService.getAllSources();
      if (!mounted) return;

      final newScreens = all.screens.map((s) => s.toMap()).toList();
      final newWindows = all.windows.map((w) => w.toMap()).toList();

      final currentList = _selectedTab == 0 ? _screens : _windows;
      final newList = _selectedTab == 0 ? newScreens : newWindows;

      bool hasChanged = currentList.length != newList.length;
      if (!hasChanged) {
        for (var i = 0; i < currentList.length; i++) {
          if (currentList[i]['title'] != newList[i]['title'] ||
              currentList[i]['thumbnail'] != newList[i]['thumbnail']) {
            hasChanged = true;
            break;
          }
        }
      }

      if (hasChanged) {
        setState(() {
          _screens = newScreens;
          _windows = newWindows;
          final updatedSources = _selectedTab == 0 ? _screens : _windows;
          if (_selectedSourceIndex >= updatedSources.length) {
            _selectedSourceIndex =
                (updatedSources.length - 1).clamp(0, 9999);
          }
        });
      }
    } catch (_) {
      // Silent catch
    } finally {
      _isAutoRefreshing = false;
    }
  }

  Future<void> _loadRealHardwareSources() async {
    setState(() => _isLoading = true);
    final all = await _hardwareService.getAllSources();

    if (mounted) {
      setState(() {
        _screens = all.screens.map((s) => s.toMap()).toList();
        _windows = all.windows.map((w) => w.toMap()).toList();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkInput : AppColors.lightCanvas;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final currentSources = _selectedTab == 0 ? _screens : _windows;

    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Responsive dialog sizing:
    // Expansive on desktop (up to 980px wide and 820px tall)
    // while gracefully adapting on smaller screens/windows down to 320px.
    final dialogWidth =
        math.min(980.0, (screenWidth - 32).clamp(320.0, screenWidth));
    final dialogHeight =
        math.min(820.0, (screenHeight - 32).clamp(420.0, screenHeight));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.screenShare,
                        size: 20,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transmitir sua Tela',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transmitindo em #${widget.channelName} • Dispositivos Reais do Sistema',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.refreshCw, size: 16, color: textMuted),
                    tooltip: 'Recarregar janelas',
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _loadRealHardwareSources();
                    },
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 18, color: textMuted),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: border),

            // 2. Tabs Selector (Telas vs Janelas)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              label: 'Telas Inteiras (${_screens.length})',
                              icon: LucideIcons.monitor,
                              isSelected: _selectedTab == 0,
                              isDark: isDark,
                              onTap: () {
                                setState(() {
                                  _selectedTab = 0;
                                  _selectedSourceIndex = 0;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              label: 'Janelas (${_windows.length})',
                              icon: LucideIcons.appWindow,
                              isSelected: _selectedTab == 1,
                              isDark: isDark,
                              onTap: () {
                                setState(() {
                                  _selectedTab = 1;
                                  _selectedSourceIndex = 0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informative Real-time Counter Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, size: 12, color: Color(0xFF4ADE80)),
                  const SizedBox(width: 6),
                  Text(
                    'Selecione uma janela/tela para transmitir',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // 3. High-Density Responsive Grid of Sources with Visual Previews
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: widget.accentColor,
                          strokeWidth: 2,
                        ),
                      )
                    : currentSources.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum item detectado',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final int crossAxisCount;
                              final double aspectRatio;

                              if (availableWidth >= 700) {
                                crossAxisCount = 3;
                                aspectRatio = 1.34;
                              } else if (availableWidth >= 420) {
                                crossAxisCount = 2;
                                aspectRatio = 1.30;
                              } else {
                                crossAxisCount = 1;
                                aspectRatio = 1.70;
                              }

                              return Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                thickness: 6,
                                radius: AppRadius.radiusSm,
                                child: GridView.builder(
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.only(right: 8, bottom: 8),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: aspectRatio,
                                  ),
                                  itemCount: currentSources.length,
                                  itemBuilder: (context, index) {
                                final source = currentSources[index];
                                final isSelected = _selectedSourceIndex == index;
                                final previewType =
                                    (source['previewType'] ?? 'nbx') as String;

                                return InkWell(
                                  onTap: () =>
                                      setState(() => _selectedSourceIndex = index),
                                  mouseCursor: SystemMouseCursors.click,
                                  borderRadius: AppRadius.borderMd,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? widget.accentColor.withValues(
                                              alpha: isDark ? 0.12 : 0.08,
                                            )
                                          : cardBg,
                                      borderRadius: AppRadius.borderMd,
                                      border: Border.all(
                                        color: isSelected
                                            ? widget.accentColor
                                            : border.withValues(alpha: 0.8),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: widget.accentColor
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Source Header
                                        Row(
                                          children: [
                                            Icon(
                                              source['icon'] as IconData,
                                              size: 15,
                                              color: isSelected
                                                  ? widget.accentColor
                                                  : (source['color'] as Color? ??
                                                      textMuted),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                source['title'] as String,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: widget.accentColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  size: 11,
                                                  color: Colors.black,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // Visual Miniature Preview
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0C0D14),
                                              borderRadius: AppRadius.borderSm,
                                              border: Border.all(
                                                color: isSelected
                                                    ? widget.accentColor
                                                        .withValues(alpha: 0.4)
                                                    : border.withValues(alpha: 0.6),
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: _buildVisualPreview(
                                              previewType,
                                              source,
                                              isDark,
                                              isSelected,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),

                                        // Bottom Label (app or resolution)
                                        Text(
                                          (source['resolution'] ?? source['app'] ?? '')
                                              as String,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9.5,
                                            color: isSelected
                                                ? widget.accentColor
                                                : textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 6),
            Divider(height: 1, color: border),

            // 4. Stream Quality & FPS Settings
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
              child: LayoutBuilder(
                builder: (context, settingsConstraints) {
                  final isNarrow = settingsConstraints.maxWidth < 540;
                  final qualitySection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUALIDADE DA TRANSMISSÃO',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildPillChip(
                            label: '720p',
                            isSelected: _selectedResolution == '720p',
                            isDark: isDark,
                            onTap: () => setState(
                                () => _selectedResolution = '720p'),
                          ),
                          _buildPillChip(
                            label: '1080p HD',
                            isSelected: _selectedResolution == '1080p',
                            isDark: isDark,
                            onTap: () => setState(
                                () => _selectedResolution = '1080p'),
                          ),
                          _buildPillChip(
                            label: '1440p 2K',
                            isSelected: _selectedResolution == '1440p',
                            isDark: isDark,
                            onTap: () => setState(
                                () => _selectedResolution = '1440p'),
                          ),
                        ],
                      ),
                    ],
                  );

                  final fpsSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAXA DE QUADROS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildPillChip(
                            label: '15 FPS',
                            isSelected: _selectedFps == 15,
                            isDark: isDark,
                            onTap: () => setState(() => _selectedFps = 15),
                          ),
                          _buildPillChip(
                            label: '30 FPS',
                            isSelected: _selectedFps == 30,
                            isDark: isDark,
                            onTap: () => setState(() => _selectedFps = 30),
                          ),
                          _buildPillChip(
                            label: '60 FPS',
                            isSelected: _selectedFps == 60,
                            isDark: isDark,
                            onTap: () => setState(() => _selectedFps = 60),
                          ),
                        ],
                      ),
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isNarrow) ...[
                        qualitySection,
                        const SizedBox(height: 8),
                        fpsSection,
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: qualitySection),
                            const SizedBox(width: 16),
                            fpsSection,
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Share Audio Checkbox Tile
                      InkWell(
                        onTap: () =>
                            setState(() => _shareAudio = !_shareAudio),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: AppRadius.borderSm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                _shareAudio
                                    ? LucideIcons.volume2
                                    : LucideIcons.volumeX,
                                size: 16,
                                color: _shareAudio
                                    ? widget.accentColor
                                    : textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Transmitir áudio do sistema e aplicativo em conjunto (48kHz)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: _shareAudio,
                                activeColor: widget.accentColor,
                                checkColor: Colors.black,
                                onChanged: (val) => setState(
                                    () => _shareAudio = val ?? true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Divider(height: 1, color: border),

            // 5. Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: textMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: currentSources.isEmpty
                        ? null
                        : () {
                            final selectedIndex = _selectedSourceIndex.clamp(
                              0,
                              currentSources.length - 1,
                            );
                            final selectedItem = currentSources[selectedIndex];
                            final selectedTitle = selectedItem['title'] as String;
                            final previewType =
                                (selectedItem['previewType'] ?? 'nbx') as String;

                            final config = ScreenShareConfig(
                              title: selectedTitle,
                              type: _selectedTab == 0 ? 'screen' : 'window',
                              resolution: _selectedResolution,
                              fps: _selectedFps,
                              shareAudio: _shareAudio,
                              previewType: previewType,
                              thumbnail: selectedItem['thumbnail'] as String?,
                              sourceId: selectedItem['id'] as String?,
                            );
                            Navigator.of(context).pop(config);
                          },
                    icon: const Icon(LucideIcons.screenShare, size: 16),
                    label: Text(
                      'Iniciar Transmissão',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor:
                          widget.accentColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: AppRadius.shapePill,
                      elevation: 0,
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

  // Realistic Visual Previews for Windows and Screens
  Widget _buildVisualPreview(
    String previewType,
    Map<String, dynamic> source,
    bool isDark,
    bool isSelected,
  ) {
    // 1. If real live screenshot is available, render it directly!
    final thumbB64 = source['thumbnail'] as String?;
    if (thumbB64 != null && thumbB64.isNotEmpty) {
      try {
        final bytes = base64Decode(thumbB64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
        );
      } catch (_) {}
    }

    // 2. Otherwise render stylized fallback preview for the application
    switch (previewType) {
      case 'screen1':
      case 'screen2':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Desktop Wallpaper graphics
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 38,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2030),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF3B4261), width: 0.6),
                  ),
                  child: Column(
                    children: [
                      Container(height: 3, color: const Color(0xFF313244)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(width: 8, height: 12, color: const Color(0xFF141520)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Container(height: 12, color: const Color(0xFF181926)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 12,
                child: Container(
                  width: 32,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 0.5),
                  ),
                ),
              ),
              // Taskbar bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 12,
                child: Container(
                  color: const Color(0xFF090A0F),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(width: 4, height: 4, color: const Color(0xFF38BDF8)),
                      const SizedBox(width: 3),
                      Container(width: 4, height: 4, color: const Color(0xFF4ADE80)),
                      const Spacer(),
                      Text(
                        '12:00',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 6,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'nbx':
        return Container(
          color: const Color(0xFF141520),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                  const SizedBox(width: 2),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle)),
                  const SizedBox(width: 2),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      source['title'] as String? ?? 'ProjectNBX',
                      style: GoogleFonts.jetBrainsMono(fontSize: 6.5, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Container(width: 14, color: const Color(0xFF1E2030)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 48, height: 3, color: const Color(0xFFF5CBA7)),
                          const SizedBox(height: 2),
                          Container(width: 72, height: 3, color: const Color(0xFF38BDF8)),
                          const SizedBox(height: 2),
                          Container(width: 36, height: 3, color: const Color(0xFF4ADE80)),
                          const SizedBox(height: 2),
                          Container(width: 54, height: 3, color: const Color(0xFFC084FC)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'vscode':
        return Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 28, height: 6, color: const Color(0xFF2D2D2D)),
                  const SizedBox(width: 2),
                  Container(width: 28, height: 6, color: const Color(0xFF1E1E1E)),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Container(width: 8, color: const Color(0xFF252526)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 60, height: 3, color: const Color(0xFF569CD6)),
                          const SizedBox(height: 2),
                          Container(width: 80, height: 3, color: const Color(0xFFDCDCAA)),
                          const SizedBox(height: 2),
                          Container(width: 45, height: 3, color: const Color(0xFFCE9178)),
                          const SizedBox(height: 2),
                          Container(width: 70, height: 3, color: const Color(0xFF9CDCFE)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'chrome':
        return Container(
          color: const Color(0xFF202124),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF323639),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(width: 6, height: 6, color: const Color(0xFF5F6368)),
                ],
              ),
              Container(
                height: 8,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF292A2D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 5, color: Color(0xFF8AB4F8)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        source['title'] as String? ?? 'Web Page',
                        style: GoogleFonts.inter(fontSize: 5, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  color: const Color(0xFF171717),
                  child: Row(
                    children: [
                      Container(width: 16, color: const Color(0xFF262626)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 40, height: 4, color: const Color(0xFF60A5FA)),
                            const SizedBox(height: 2),
                            Container(width: 60, height: 2, color: Colors.white38),
                            const SizedBox(height: 2),
                            Container(width: 50, height: 2, color: Colors.white38),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'spotify':
        return Container(
          color: const Color(0xFF121212),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(LucideIcons.music, size: 16, color: Color(0xFF1DB954)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source['title'] as String? ?? 'Spotify Audio',
                      style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('48 kHz Opus High Fidelity', style: GoogleFonts.inter(fontSize: 6, color: Colors.white54)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 2, height: 6, color: const Color(0xFF1DB954)),
                        const SizedBox(width: 1.5),
                        Container(width: 2, height: 10, color: const Color(0xFF1DB954)),
                        const SizedBox(width: 1.5),
                        Container(width: 2, height: 4, color: const Color(0xFF1DB954)),
                        const SizedBox(width: 1.5),
                        Container(width: 2, height: 8, color: const Color(0xFF1DB954)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'discord':
        return Container(
          color: const Color(0xFF313338),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(width: 10, color: const Color(0xFF1E1F22)),
              const SizedBox(width: 3),
              Container(width: 14, color: const Color(0xFF2B2D31)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF5865F2), shape: BoxShape.circle)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            source['title'] as String? ?? 'Discord',
                            style: GoogleFonts.inter(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(width: 40, height: 3, color: Colors.white38),
                    const SizedBox(height: 2),
                    Container(width: 55, height: 3, color: Colors.white24),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'terminal':
        return Container(
          color: const Color(0xFF0C0C0C),
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PS D:\\projectNBX> ./run_api.ps1', style: GoogleFonts.jetBrainsMono(fontSize: 6, color: const Color(0xFF4ADE80))),
              const SizedBox(height: 2),
              Text('[LiveKit] SFU WebRTC room online', style: GoogleFonts.jetBrainsMono(fontSize: 5.5, color: const Color(0xFF38BDF8))),
              const SizedBox(height: 2),
              Text('[WS] Broadcast channel ready', style: GoogleFonts.jetBrainsMono(fontSize: 5.5, color: Colors.white70)),
            ],
          ),
        );

      case 'game':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF450A0A), Color(0xFF18181B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(LucideIcons.gamepad2, size: 22, color: Colors.white.withValues(alpha: 0.4)),
              ),
              Positioned(
                bottom: 4,
                left: 6,
                child: Text('180 KM/H • GEAR 5', style: GoogleFonts.jetBrainsMono(fontSize: 6, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
              ),
            ],
          ),
        );

      case 'youtube':
        return Container(
          color: const Color(0xFF0F0F0F),
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow, size: 8, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      source['title'] as String? ?? 'YouTube Video',
                      style: GoogleFonts.inter(fontSize: 6, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, size: 14, color: Color(0xFFFF0000)),
                ),
              ),
              const Spacer(),
              // Scrubber bar
              Row(
                children: [
                  Container(width: 32, height: 2, color: const Color(0xFFFF0000)),
                  Container(width: 24, height: 2, color: Colors.white38),
                  Expanded(child: Container(height: 2, color: Colors.white12)),
                ],
              ),
            ],
          ),
        );

      case 'android_studio':
        return Container(
          color: const Color(0xFF1E1F22),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3DDC84),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Icon(Icons.android, size: 5, color: Colors.black)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'main.dart — Flutter',
                      style: GoogleFonts.jetBrainsMono(fontSize: 6, fontWeight: FontWeight.bold, color: const Color(0xFF3DDC84)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Container(width: 10, color: const Color(0xFF2B2D30)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 55, height: 3, color: const Color(0xFFCC7832)),
                          const SizedBox(height: 2),
                          Container(width: 75, height: 3, color: const Color(0xFF6897BB)),
                          const SizedBox(height: 2),
                          Container(width: 40, height: 3, color: const Color(0xFF9876AA)),
                          const SizedBox(height: 2),
                          Container(width: 65, height: 3, color: const Color(0xFF3DDC84)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'goland':
        return Container(
          color: const Color(0xFF1E1F22),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.code2, size: 8, color: Color(0xFF00ADD8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'main.go — GoLand',
                      style: GoogleFonts.jetBrainsMono(fontSize: 6, fontWeight: FontWeight.bold, color: const Color(0xFF00ADD8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Container(width: 10, color: const Color(0xFF2B2D30)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 45, height: 3, color: const Color(0xFF00ADD8)),
                          const SizedBox(height: 2),
                          Container(width: 70, height: 3, color: const Color(0xFFE8BF6A)),
                          const SizedBox(height: 2),
                          Container(width: 50, height: 3, color: const Color(0xFF6A8759)),
                          const SizedBox(height: 2),
                          Container(width: 80, height: 3, color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'figma':
        return Container(
          color: const Color(0xFF2C2C2C),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(width: 12, color: const Color(0xFF1E1E1E)),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFF24E1E).withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.penTool, size: 12, color: Color(0xFFF24E1E)),
                        const SizedBox(height: 2),
                        Text(
                          'Frame 1',
                          style: GoogleFonts.inter(fontSize: 5.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 14, color: const Color(0xFF1E1E1E)),
            ],
          ),
        );

      case 'github':
        return Container(
          color: const Color(0xFF1F2428),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.gitBranch, size: 8, color: Color(0xFF8957E5)),
                  const SizedBox(width: 3),
                  Text('main', style: GoogleFonts.jetBrainsMono(fontSize: 6, fontWeight: FontWeight.bold, color: const Color(0xFF8957E5))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF238636), borderRadius: BorderRadius.circular(2)),
                    child: Text('Fetch', style: GoogleFonts.inter(fontSize: 5, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  color: const Color(0xFF161B22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 60, height: 3, color: Colors.white70),
                      const SizedBox(height: 2),
                      Container(width: 40, height: 2, color: const Color(0xFF3FB950)),
                      const SizedBox(height: 2),
                      Container(width: 50, height: 2, color: const Color(0xFFF85149)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'whatsapp':
        return Container(
          color: const Color(0xFF111B21),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(width: 14, color: const Color(0xFF202C33)),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle)),
                        const SizedBox(width: 3),
                        Text('WhatsApp', style: GoogleFonts.inter(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF005C4B), borderRadius: BorderRadius.circular(4)),
                        child: Text('Online', style: GoogleFonts.inter(fontSize: 5.5, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'rgb':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SignalRGB CHROMA',
                style: GoogleFonts.jetBrainsMono(fontSize: 6.5, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        );

      default:
        return Center(
          child: Icon(source['icon'] as IconData, size: 20, color: widget.accentColor),
        );
    }
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: AppRadius.borderSm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated)
              : Colors.transparent,
          borderRadius: AppRadius.borderSm,
          border: isSelected
              ? Border.all(
                  color: widget.accentColor.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? widget.accentColor
                  : (isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: AppRadius.borderSm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.accentColor
              : (isDark ? AppColors.darkInput : AppColors.lightCanvas),
          borderRadius: AppRadius.borderSm,
          border: Border.all(
            color: isSelected
                ? widget.accentColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (widget.accentColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white)
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
