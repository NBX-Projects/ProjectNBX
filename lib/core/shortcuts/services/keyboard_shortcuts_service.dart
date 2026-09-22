import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:projectnbx/core/shortcuts/controllers/shortcuts_controller.dart';
import 'package:projectnbx/core/shortcuts/models/app_shortcut_action.dart';
import 'package:projectnbx/features/voice/controllers/audio_settings_controller.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';

class KeyboardShortcutsService {
  static final KeyboardShortcutsService instance =
      KeyboardShortcutsService._internal();

  KeyboardShortcutsService._internal();

  final Map<AppShortcutAction, Set<VoidCallback>> _handlers = {};
  dynamic _ref;
  bool _isInitialized = false;

  /// Flag para suspender atalhos enquanto o usuário grava uma nova tecla
  bool isRecording = false;

  HotKey? _systemPttHotKey;

  void initialize(dynamic ref) {
    _ref = ref;
    if (!_isInitialized) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      _isInitialized = true;
      debugPrint('[Shortcuts] Global HardwareKeyboard handler initialized.');
    }
    syncPttHotKey();
  }

  Future<void> syncPttHotKey() async {
    if (_ref == null) return;
    try {
      final AudioSettings audioSettings =
          (_ref as dynamic).read(audioSettingsProvider) as AudioSettings;
      await _registerSystemPttHotKey(
        audioSettings.pttKeyId,
        audioSettings.isPushToTalk,
      );
    } catch (e) {
      debugPrint('[Shortcuts] Erro ao sincronizar PTT hotkey: $e');
    }
  }

  Future<void> _registerSystemPttHotKey(int keyId, bool isPttEnabled) async {
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      return;
    }

    try {
      if (_systemPttHotKey != null) {
        await hotKeyManager.unregister(_systemPttHotKey!);
        _systemPttHotKey = null;
      }
    } catch (_) {}

    if (!isPttEnabled) return;

    try {
      final hotKey = HotKey(
        key: LogicalKeyboardKey(keyId),
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (hotKey) {
          try {
            (_ref as dynamic)
                ?.read(voiceStateProvider.notifier)
                .setPttPressed(true);
          } catch (_) {}
        },
        keyUpHandler: (hotKey) {
          try {
            (_ref as dynamic)
                ?.read(voiceStateProvider.notifier)
                .setPttPressed(false);
          } catch (_) {}
        },
      );
      _systemPttHotKey = hotKey;
      debugPrint(
          '[Shortcuts] Global system PTT hotkey registrado com sucesso: 0x${keyId.toRadixString(16)}');
    } catch (e) {
      debugPrint(
          '[Shortcuts] Aviso: Não foi possível registrar global hotkey PTT ($e)');
    }
  }

  Future<void> dispose() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      try {
        if (_systemPttHotKey != null) {
          await hotKeyManager.unregister(_systemPttHotKey!);
          _systemPttHotKey = null;
        }
      } catch (_) {}
    }
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _isInitialized = false;
  }

  void registerHandler(AppShortcutAction action, VoidCallback handler) {
    _handlers.putIfAbsent(action, () => {}).add(handler);
  }

  void unregisterHandler(AppShortcutAction action, VoidCallback handler) {
    _handlers[action]?.remove(handler);
    if (_handlers[action]?.isEmpty == true) {
      _handlers.remove(action);
    }
  }

  bool _isEditableFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final widget = focus.context?.widget;
    return widget is EditableText;
  }

  bool _isSpecialKey(int keyId) {
    return keyId == LogicalKeyboardKey.escape.keyId ||
        keyId == LogicalKeyboardKey.capsLock.keyId ||
        keyId == 0x100000104 ||
        keyId == 0x00100000014 ||
        keyId == LogicalKeyboardKey.space.keyId ||
        keyId == LogicalKeyboardKey.shiftLeft.keyId ||
        keyId == LogicalKeyboardKey.shiftRight.keyId ||
        keyId == LogicalKeyboardKey.controlLeft.keyId ||
        keyId == LogicalKeyboardKey.controlRight.keyId ||
        keyId == LogicalKeyboardKey.altLeft.keyId ||
        keyId == LogicalKeyboardKey.altRight.keyId ||
        keyId == LogicalKeyboardKey.metaLeft.keyId ||
        keyId == LogicalKeyboardKey.metaRight.keyId ||
        (keyId >= LogicalKeyboardKey.f1.keyId &&
            keyId <= LogicalKeyboardKey.f12.keyId);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (_ref == null || isRecording) return false;

    // 1. Processamento de Push-to-Talk (PTT)
    try {
      final AudioSettings audioSettings =
          (_ref as dynamic).read(audioSettingsProvider) as AudioSettings;

      if (audioSettings.isPushToTalk) {
        final matchesKey = event.logicalKey.keyId == audioSettings.pttKeyId ||
            (audioSettings.pttKeyId == 0x100000104 &&
                event.logicalKey == LogicalKeyboardKey.capsLock);

        if (matchesKey) {
          final inEditable = _isEditableFocused();
          final isCharKey = event.logicalKey.keyLabel.length == 1 &&
              !_isSpecialKey(event.logicalKey.keyId);

          // Não bloqueia digitação se for uma letra comum dentro de caixa de texto
          if (!(inEditable && isCharKey)) {
            if (event is KeyDownEvent || event is KeyRepeatEvent) {
              (_ref as dynamic)
                  .read(voiceStateProvider.notifier)
                  .setPttPressed(true);
              return true;
            } else if (event is KeyUpEvent) {
              (_ref as dynamic)
                  .read(voiceStateProvider.notifier)
                  .setPttPressed(false);
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Shortcuts] Erro ao processar PTT: $e');
    }

    // 2. Atalhos de Ação (disparados apenas no evento KeyDown)
    if (event is! KeyDownEvent) return false;

    final ShortcutsState shortcutsState =
        (_ref as dynamic).read(shortcutsProvider) as ShortcutsState;
    final inEditable = _isEditableFocused();

    for (final action in AppShortcutAction.values) {
      final combo = shortcutsState.getCombination(action);
      if (combo == null) continue;

      if (combo.matches(event)) {
        // Se estiver digitando em campo de texto, ignora atalhos de tecla simples sem modificador
        final hasModifier = combo.ctrl || combo.alt || combo.meta;
        if (inEditable && !hasModifier && !_isSpecialKey(combo.keyId)) {
          return false;
        }

        debugPrint(
            '[Shortcuts] Disparado: ${action.title} (${combo.toReadableString()})');
        _dispatchAction(action);
        return true; // Consome o evento com prioridade
      }
    }

    return false;
  }

  void _dispatchAction(AppShortcutAction action) {
    final listeners = _handlers[action];
    if (listeners != null && listeners.isNotEmpty) {
      for (final listener in List<VoidCallback>.from(listeners)) {
        try {
          listener();
        } catch (e) {
          debugPrint(
              '[Shortcuts] Erro ao executar handler para ${action.id}: $e');
        }
      }
    }
  }
}

final keyboardShortcutsServiceProvider =
    Provider<KeyboardShortcutsService>((ref) {
  final service = KeyboardShortcutsService.instance;
  service.initialize(ref);
  return service;
});
