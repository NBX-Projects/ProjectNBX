import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/shortcuts/models/app_shortcut_action.dart';
import 'package:projectnbx/core/shortcuts/models/shortcut_combination.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShortcutsState {
  final Map<AppShortcutAction, ShortcutCombination?> bindings;
  final bool isLoaded;

  const ShortcutsState({
    required this.bindings,
    this.isLoaded = false,
  });

  ShortcutsState copyWith({
    Map<AppShortcutAction, ShortcutCombination?>? bindings,
    bool? isLoaded,
  }) {
    return ShortcutsState(
      bindings: bindings ?? this.bindings,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  ShortcutCombination? getCombination(AppShortcutAction action) {
    if (bindings.containsKey(action)) {
      return bindings[action];
    }
    return action.defaultCombination;
  }

  bool isCustomized(AppShortcutAction action) {
    if (!bindings.containsKey(action)) return false;
    final current = bindings[action];
    final def = action.defaultCombination;
    return current != def;
  }

  AppShortcutAction? findConflict(
    ShortcutCombination combination,
    AppShortcutAction targetAction,
  ) {
    for (final action in AppShortcutAction.values) {
      if (action == targetAction) continue;
      final existingCombo = getCombination(action);
      if (existingCombo != null && existingCombo == combination) {
        return action;
      }
    }
    return null;
  }
}

class ShortcutsNotifier extends StateNotifier<ShortcutsState> {
  static const String _storageKey = 'user_keyboard_shortcuts_v1';

  ShortcutsNotifier()
      : super(const ShortcutsState(bindings: {}, isLoaded: false)) {
    loadShortcuts();
  }

  Future<void> loadShortcuts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final Map<AppShortcutAction, ShortcutCombination?> loaded = {};

        for (final entry in decoded.entries) {
          final action = AppShortcutAction.fromId(entry.key);
          if (action != null) {
            if (entry.value == null) {
              loaded[action] = null;
            } else {
              loaded[action] = ShortcutCombination.fromJson(
                entry.value as Map<String, dynamic>,
              );
            }
          }
        }
        state = state.copyWith(bindings: loaded, isLoaded: true);
        return;
      }
    } catch (e) {
      debugPrint('[Shortcuts] Error loading custom shortcuts: $e');
    }
    state = state.copyWith(bindings: {}, isLoaded: true);
  }

  Future<void> setShortcut(
    AppShortcutAction action,
    ShortcutCombination? combination,
  ) async {
    final updated = Map<AppShortcutAction, ShortcutCombination?>.from(
      state.bindings,
    );

    // If another action has this combination, remove it from that action (prevent duplicate firing)
    if (combination != null) {
      for (final otherAction in AppShortcutAction.values) {
        if (otherAction == action) continue;
        final currentCombo = state.getCombination(otherAction);
        if (currentCombo != null && currentCombo == combination) {
          updated[otherAction] = null;
        }
      }
    }

    updated[action] = combination;
    state = state.copyWith(bindings: updated);
    await _saveToDisk();
  }

  Future<void> resetShortcut(AppShortcutAction action) async {
    final updated = Map<AppShortcutAction, ShortcutCombination?>.from(
      state.bindings,
    );
    updated.remove(action);
    state = state.copyWith(bindings: updated);
    await _saveToDisk();
  }

  Future<void> resetAllToDefault() async {
    state = state.copyWith(bindings: {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  AppShortcutAction? findConflict(
    AppShortcutAction targetAction,
    ShortcutCombination combination,
  ) {
    return state.findConflict(combination, targetAction);
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> rawMap = {};
      for (final entry in state.bindings.entries) {
        rawMap[entry.key.id] = entry.value?.toJson();
      }
      await prefs.setString(_storageKey, jsonEncode(rawMap));
    } catch (e) {
      debugPrint('[Shortcuts] Error saving shortcuts: $e');
    }
  }
}

final shortcutsProvider =
    StateNotifierProvider<ShortcutsNotifier, ShortcutsState>((ref) {
  return ShortcutsNotifier();
});
