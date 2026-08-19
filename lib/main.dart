import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/layout/main_layout.dart';

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

  runApp(
    const ProviderScope(
      child: ProjectNBXApp(),
    ),
  );
}

class ProjectNBXApp extends StatelessWidget {
  const ProjectNBXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProjectNBX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
