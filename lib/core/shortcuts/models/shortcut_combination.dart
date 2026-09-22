import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class ShortcutCombination {
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;
  final int keyId;
  final String keyLabel;

  const ShortcutCombination({
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
    required this.keyId,
    required this.keyLabel,
  });

  LogicalKeyboardKey get logicalKey => LogicalKeyboardKey(keyId);

  bool matches(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final pressedKey = event.logicalKey;
    final pressedId = pressedKey.keyId;

    bool keyMatches = (pressedId == keyId);
    if (!keyMatches) {
      // Normalização para letras ASCII (A-Z vs a-z) que variam quando Shift está pressionado
      final isChar = (keyId >= 0x61 && keyId <= 0x7a) || (keyId >= 0x41 && keyId <= 0x5a);
      final isPressedChar = (pressedId >= 0x61 && pressedId <= 0x7a) || (pressedId >= 0x41 && pressedId <= 0x5a);
      if (isChar && isPressedChar) {
        final normExpected = (keyId >= 0x41 && keyId <= 0x5a) ? keyId + 32 : keyId;
        final normPressed = (pressedId >= 0x41 && pressedId <= 0x5a) ? pressedId + 32 : pressedId;
        keyMatches = (normExpected == normPressed);
      }
    }

    if (!keyMatches && keyLabel.isNotEmpty && pressedKey.keyLabel.isNotEmpty) {
      if (keyLabel.trim().toLowerCase() == pressedKey.keyLabel.trim().toLowerCase()) {
        keyMatches = true;
      }
    }

    if (!keyMatches) return false;

    // Check modifiers using HardwareKeyboard instance
    final hw = HardwareKeyboard.instance;

    final isCtrlPressed = hw.isControlPressed;
    final isShiftPressed = hw.isShiftPressed;
    final isAltPressed = hw.isAltPressed;
    final isMetaPressed = hw.isMetaPressed;

    // Special case: if the trigger key itself is a modifier, don't require the modifier flag
    final keyIsCtrl = pressedKey == LogicalKeyboardKey.controlLeft ||
        pressedKey == LogicalKeyboardKey.controlRight ||
        pressedKey == LogicalKeyboardKey.control;
    final keyIsShift = pressedKey == LogicalKeyboardKey.shiftLeft ||
        pressedKey == LogicalKeyboardKey.shiftRight ||
        pressedKey == LogicalKeyboardKey.shift;
    final keyIsAlt = pressedKey == LogicalKeyboardKey.altLeft ||
        pressedKey == LogicalKeyboardKey.altRight ||
        pressedKey == LogicalKeyboardKey.alt;
    final keyIsMeta = pressedKey == LogicalKeyboardKey.metaLeft ||
        pressedKey == LogicalKeyboardKey.metaRight ||
        pressedKey == LogicalKeyboardKey.meta;

    if (!keyIsCtrl && ctrl != isCtrlPressed) return false;
    if (!keyIsShift && shift != isShiftPressed) return false;
    if (!keyIsAlt && alt != isAltPressed) return false;
    if (!keyIsMeta && meta != isMetaPressed) return false;

    return true;
  }

  String toReadableString() {
    final parts = <String>[];
    if (ctrl) parts.add('Ctrl');
    if (alt) parts.add('Alt');
    if (shift) parts.add('Shift');
    if (meta) parts.add('Meta');

    String formattedLabel = keyLabel;
    // Map common key labels to cleaner user display
    if (keyId == LogicalKeyboardKey.escape.keyId) {
      formattedLabel = 'Esc';
    } else if (keyId == LogicalKeyboardKey.enter.keyId ||
        keyId == LogicalKeyboardKey.numpadEnter.keyId) {
      formattedLabel = 'Enter';
    } else if (keyId == LogicalKeyboardKey.space.keyId) {
      formattedLabel = 'Espaço';
    } else if (keyId == LogicalKeyboardKey.capsLock.keyId) {
      formattedLabel = 'Caps Lock';
    } else if (keyId == LogicalKeyboardKey.backspace.keyId) {
      formattedLabel = 'Backspace';
    } else if (keyId == LogicalKeyboardKey.tab.keyId) {
      formattedLabel = 'Tab';
    } else if (keyId == LogicalKeyboardKey.delete.keyId) {
      formattedLabel = 'Del';
    } else if (formattedLabel.length == 1) {
      formattedLabel = formattedLabel.toUpperCase();
    }

    // Avoid duplicate if key is modifier itself
    if (parts.isEmpty || !parts.contains(formattedLabel)) {
      parts.add(formattedLabel);
    }

    return parts.join(' + ');
  }

  Map<String, dynamic> toJson() {
    return {
      'ctrl': ctrl,
      'shift': shift,
      'alt': alt,
      'meta': meta,
      'keyId': keyId,
      'keyLabel': keyLabel,
    };
  }

  factory ShortcutCombination.fromJson(Map<String, dynamic> json) {
    return ShortcutCombination(
      ctrl: json['ctrl'] as bool? ?? false,
      shift: json['shift'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
      meta: json['meta'] as bool? ?? false,
      keyId: json['keyId'] as int,
      keyLabel: json['keyLabel'] as String? ?? 'Key',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortcutCombination &&
          runtimeType == other.runtimeType &&
          ctrl == other.ctrl &&
          shift == other.shift &&
          alt == other.alt &&
          meta == other.meta &&
          keyId == other.keyId;

  @override
  int get hashCode =>
      ctrl.hashCode ^
      shift.hashCode ^
      alt.hashCode ^
      meta.hashCode ^
      keyId.hashCode;
}
