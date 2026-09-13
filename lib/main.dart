import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/theme/app_theme.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/features/auth/screens/login_screen.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        titleBarStyle: TitleBarStyle.normal,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Desktop window manager initialization error: $e');
    }
  }

  runApp(const ProviderScope(child: ProjectNBXApp()));
}

class ProjectNBXApp extends ConsumerWidget {
  const ProjectNBXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ProjectNBX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const LoginScreen(),
    );
  }
}
