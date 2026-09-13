import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop window control buttons (Minimize, Maximize/Restore, Close)
/// designed to sit flush at the top-right corner of the window.
class WindowControls extends StatefulWidget {
  const WindowControls({
    super.key,
    this.height = 56,
    this.buttonWidth = 46,
  });

  final double height;
  final double buttonWidth;

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> _checkMaximized() async {
    final max = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = max;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultFg = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final hoverBg = isDark
        ? AppColors.darkSurfaceElevated
        : const Color(0xFFE2E8F0);

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Minimize Button
          _WindowButton(
            width: widget.buttonWidth,
            height: widget.height,
            tooltip: 'Minimizar',
            hoverColor: hoverBg,
            iconColor: defaultFg,
            icon: const Icon(LucideIcons.minus, size: 14),
            onPressed: () => windowManager.minimize(),
          ),

          // Maximize / Restore Button
          _WindowButton(
            width: widget.buttonWidth,
            height: widget.height,
            tooltip: _isMaximized ? 'Restaurar' : 'Maximizar',
            hoverColor: hoverBg,
            iconColor: defaultFg,
            icon: Icon(
              _isMaximized ? LucideIcons.copy : LucideIcons.square,
              size: 13,
            ),
            onPressed: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),

          // Close Button (Red on Hover)
          _WindowButton(
            width: widget.buttonWidth,
            height: widget.height,
            tooltip: 'Fechar',
            hoverColor: const Color(0xFFE81123),
            hoverIconColor: Colors.white,
            iconColor: defaultFg,
            icon: const Icon(LucideIcons.x, size: 15),
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.width,
    required this.height,
    required this.tooltip,
    required this.hoverColor,
    required this.iconColor,
    required this.icon,
    required this.onPressed,
    this.hoverIconColor,
  });

  final double width;
  final double height;
  final String tooltip;
  final Color hoverColor;
  final Color iconColor;
  final Color? hoverIconColor;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            color: _isHovered ? widget.hoverColor : Colors.transparent,
            child: IconTheme(
              data: IconThemeData(
                color: _isHovered
                    ? (widget.hoverIconColor ?? widget.iconColor)
                    : widget.iconColor,
              ),
              child: widget.icon,
            ),
          ),
        ),
      ),
    );
  }
}
