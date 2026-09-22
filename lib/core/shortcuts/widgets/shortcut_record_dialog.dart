import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/shortcuts/controllers/shortcuts_controller.dart';
import 'package:projectnbx/core/shortcuts/models/app_shortcut_action.dart';
import 'package:projectnbx/core/shortcuts/models/shortcut_combination.dart';
import 'package:projectnbx/core/shortcuts/services/keyboard_shortcuts_service.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';

class ShortcutRecordDialog extends ConsumerStatefulWidget {
  final AppShortcutAction action;
  final ShortcutCombination? currentCombination;

  const ShortcutRecordDialog({
    super.key,
    required this.action,
    required this.currentCombination,
  });

  static Future<void> show(
    BuildContext context, {
    required AppShortcutAction action,
    required ShortcutCombination? currentCombination,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShortcutRecordDialog(
        action: action,
        currentCombination: currentCombination,
      ),
    );
  }

  @override
  ConsumerState<ShortcutRecordDialog> createState() =>
      _ShortcutRecordDialogState();
}

class _ShortcutRecordDialogState extends ConsumerState<ShortcutRecordDialog> {
  ShortcutCombination? _recordedCombination;
  final bool _isListening = true;
  AppShortcutAction? _conflictAction;

  @override
  void initState() {
    super.initState();
    KeyboardShortcutsService.instance.isRecording = true;
    _recordedCombination = widget.currentCombination;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    KeyboardShortcutsService.instance.isRecording = false;
    super.dispose();
  }

  bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.meta;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isListening) return false;
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final hw = HardwareKeyboard.instance;

    // Modificadores puros sozinhos não concluem o atalho, apenas sinalizam
    if (_isModifier(key)) {
      setState(() {
        _recordedCombination = ShortcutCombination(
          keyId: 0,
          keyLabel: '',
          ctrl: hw.isControlPressed,
          shift: hw.isShiftPressed,
          alt: hw.isAltPressed,
          meta: hw.isMetaPressed,
        );
      });
      return true;
    }

    // Tecla de ação final detectada com ou sem modificadores
    final combo = ShortcutCombination(
      keyId: key.keyId,
      keyLabel: key.keyLabel.isNotEmpty
          ? key.keyLabel
          : 'Key 0x${key.keyId.toRadixString(16)}',
      ctrl: hw.isControlPressed,
      shift: hw.isShiftPressed,
      alt: hw.isAltPressed,
      meta: hw.isMetaPressed,
    );

    // Checa conflito com outras ações cadastradas
    final shortcutsState = ref.read(shortcutsProvider);
    final conflict = shortcutsState.findConflict(combo, widget.action);

    setState(() {
      _recordedCombination = combo;
      _conflictAction = conflict;
    });

    return true;
  }

  void _saveAndClose() {
    if (_recordedCombination != null && _recordedCombination!.keyId != 0) {
      ref.read(shortcutsProvider.notifier).setShortcut(
            widget.action,
            _recordedCombination!,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.keyboard,
                  size: 20,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gravar Atalho: ${widget.action.title}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Pressione a combinação de teclas desejada no teclado (ex: Ctrl + M).',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated,
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: _conflictAction != null
                      ? Colors.amber.shade700
                      : (isDark
                          ? AppColors.darkBorderFocus
                          : AppColors.lightBorderFocus),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _recordedCombination == null ||
                          _recordedCombination!.keyId == 0
                      ? 'Aguardando teclas...'
                      : _recordedCombination!.toReadableString(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
            if (_conflictAction != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    size: 16,
                    color: Colors.amber.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este atalho substituirá a ação: "${_conflictAction!.title}"',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _recordedCombination != null &&
                          _recordedCombination!.keyId != 0
                      ? _saveAndClose
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderSm,
                    ),
                  ),
                  child: const Text('Salvar Atalho'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
