import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/shortcuts/services/keyboard_shortcuts_service.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/voice/controllers/audio_settings_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PttKeyRecordDialog extends StatefulWidget {
  final bool isDark;
  final AudioSettingsNotifier notifier;
  final String currentKeyLabel;

  const PttKeyRecordDialog({
    super.key,
    required this.isDark,
    required this.notifier,
    required this.currentKeyLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDark,
    required AudioSettingsNotifier notifier,
    required String currentKeyLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => PttKeyRecordDialog(
        isDark: isDark,
        notifier: notifier,
        currentKeyLabel: currentKeyLabel,
      ),
    );
  }

  @override
  State<PttKeyRecordDialog> createState() => _PttKeyRecordDialogState();
}

class _PttKeyRecordDialogState extends State<PttKeyRecordDialog> {
  LogicalKeyboardKey? _recordedKey;

  @override
  void initState() {
    super.initState();
    KeyboardShortcutsService.instance.isRecording = true;
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    KeyboardShortcutsService.instance.isRecording = false;
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && mounted) {
      setState(() {
        _recordedKey = event.logicalKey;
      });
      widget.notifier.setPttKey(event.logicalKey);
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceElevated;
    final primaryColor = widget.isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final textPrimary = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = widget.isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final displayLabel = _recordedKey != null
        ? (_recordedKey! == LogicalKeyboardKey.space
              ? 'Space'
              : (_recordedKey!.keyLabel.trim().isNotEmpty
                    ? _recordedKey!.keyLabel
                    : 'Tecla 0x${_recordedKey!.keyId.toRadixString(16)}'))
        : widget.currentKeyLabel;

    return Dialog(
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.radio, size: 28, color: primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Definir Tecla Push-to-Talk (PTT)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pressione qualquer tecla do teclado (ex: Caps Lock, Espaço, V, etc.) para atribuir como botão de fala.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(
                    color: _recordedKey != null
                        ? primaryColor
                        : (widget.isDark
                              ? AppColors.darkBorderFocus
                              : AppColors.lightBorderFocus),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _recordedKey != null
                        ? 'Tecla Registrada: $displayLabel'
                        : 'Aguardando tecla... (Atual: $displayLabel)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
