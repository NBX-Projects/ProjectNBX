import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/api_status_controller.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/shortcuts/models/app_shortcut_action.dart';
import 'package:projectnbx/core/shortcuts/services/keyboard_shortcuts_service.dart';
import 'package:projectnbx/core/theme/app_theme.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/updater/update_controller.dart';
import 'package:projectnbx/core/widgets/api_offline_screen.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/screens/login_screen.dart';
import 'package:projectnbx/features/home/screens/home_screen.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';
import 'package:projectnbx/features/settings/screens/settings_screen.dart';
import 'package:projectnbx/features/voice/controllers/audio_settings_controller.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/widgets/quick_audio_device_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();

  // Desktop Window Configuration
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1100, 720),
        minimumSize: Size(800, 550),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'ProjectNBX',
        titleBarStyle: TitleBarStyle.hidden,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Desktop window manager initialization error: $e');
    }
  }

  // Restore custom backend host from SharedPreferences if configured
  try {
    final prefs = await SharedPreferences.getInstance();
    final customHost = prefs.getString('custom_backend_host');
    if (customHost != null && customHost.isNotEmpty) {
      ApiClient.setCustomBaseUrl(customHost);
    }
  } catch (_) {}

  runApp(const ProviderScope(child: ProjectNBXApp()));
}

class ProjectNBXApp extends ConsumerStatefulWidget {
  const ProjectNBXApp({super.key});

  @override
  ConsumerState<ProjectNBXApp> createState() => _ProjectNBXAppState();
}

class _ProjectNBXAppState extends ConsumerState<ProjectNBXApp> {
  @override
  void initState() {
    super.initState();
    _setupGlobalShortcuts();
  }

  void _setupGlobalShortcuts() {
    final shortcuts = KeyboardShortcutsService.instance;
    shortcuts.initialize(ref);

    shortcuts.registerHandler(AppShortcutAction.toggleMute, () {
      ref.read(voiceStateProvider.notifier).toggleMic();
    });

    shortcuts.registerHandler(AppShortcutAction.toggleDeafen, () {
      ref.read(voiceStateProvider.notifier).toggleDeafened();
    });

    shortcuts.registerHandler(AppShortcutAction.disconnectVoice, () {
      ref.read(voiceStateProvider.notifier).disconnectVoice();
    });

    shortcuts.registerHandler(AppShortcutAction.toggleTheme, () {
      ref.read(themeModeProvider.notifier).toggleTheme();
    });

    shortcuts.registerHandler(AppShortcutAction.quickAudioDevices, () {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        QuickAudioDeviceMenu.show(ctx, isInput: true);
      }
    });

    shortcuts.registerHandler(AppShortcutAction.openCreateServer, () {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        CreateServerDialog.show(ctx);
      }
    });

    shortcuts.registerHandler(AppShortcutAction.openSettings, () {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        SettingsScreen.show(ctx);
      }
    });

    shortcuts.registerHandler(AppShortcutAction.closeOrEscape, () {
      rootNavigatorKey.currentState?.maybePop();
    });

    shortcuts.registerHandler(AppShortcutAction.checkForUpdates, () {
      ref.read(updateControllerProvider.notifier).checkForUpdates(silent: false);
    });

    shortcuts.registerHandler(AppShortcutAction.logout, () {
      ref.read(authControllerProvider.notifier).logout();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Eagerly keep WebSocket client and Shortcuts service active
    ref.watch(websocketClientProvider);
    ref.watch(keyboardShortcutsServiceProvider);

    ref.listen<AudioSettings>(audioSettingsProvider, (previous, next) {
      if (previous?.isPushToTalk != next.isPushToTalk ||
          previous?.pttKeyId != next.pttKeyId) {
        KeyboardShortcutsService.instance.syncPttHotKey();
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authControllerProvider);
    final apiStatus = ref.watch(apiStatusProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'ProjectNBX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      home: apiStatus.isOffline
          ? const ApiOfflineScreen()
          : (authState.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen()),
    );
  }
}
