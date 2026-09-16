import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/theme/app_theme.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/screens/login_screen.dart';
import 'package:projectnbx/features/home/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();

  // Desktop Window Configuration
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
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

class ProjectNBXApp extends ConsumerWidget {
  const ProjectNBXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly keep WebSocket client active across whole app lifecycle
    ref.watch(websocketClientProvider);

    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'ProjectNBX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
