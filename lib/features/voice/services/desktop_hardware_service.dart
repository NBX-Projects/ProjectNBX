import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RealScreenInfo {
  final String id;
  final String title;
  final String resolution;
  final bool isPrimary;
  final IconData icon;
  final String previewType;
  final String? thumbnail;

  const RealScreenInfo({
    required this.id,
    required this.title,
    required this.resolution,
    required this.isPrimary,
    required this.icon,
    required this.previewType,
    this.thumbnail,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'resolution': resolution,
        'isPrimary': isPrimary,
        'icon': icon,
        'previewType': previewType,
        'thumbnail': thumbnail,
      };
}

class RealWindowInfo {
  final String title;
  final String app;
  final IconData icon;
  final Color color;
  final String previewType;
  final String? thumbnail;

  const RealWindowInfo({
    required this.title,
    required this.app,
    required this.icon,
    required this.color,
    required this.previewType,
    this.thumbnail,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'app': app,
        'icon': icon,
        'color': color,
        'previewType': previewType,
        'thumbnail': thumbnail,
      };
}

class DesktopHardwareService {
  const DesktopHardwareService();

  Future<({List<RealScreenInfo> screens, List<RealWindowInfo> windows})> getAllSources() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      try {
        final scriptFile = io.File('scripts/get_taskbar_sources.ps1');
        final scriptPath = scriptFile.existsSync()
            ? scriptFile.absolute.path
            : 'scripts/get_taskbar_sources.ps1';

        final result = await io.Process.run(
          'powershell',
          [
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            scriptPath,
          ],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        ).timeout(const Duration(seconds: 4));

        if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
          final raw = jsonDecode((result.stdout as String).trim()) as Map<String, dynamic>;
          final rawScreens = (raw['screens'] as List?) ?? [];
          final rawWindows = (raw['windows'] as List?) ?? [];

          final screens = <RealScreenInfo>[];
          for (var i = 0; i < rawScreens.length; i++) {
            final s = rawScreens[i] as Map<String, dynamic>;
            final id = s['id'] ?? 'screen_${i + 1}';
            final title = s['title'] ?? 'Tela ${i + 1}';
            final res = s['resolution'] ?? '1920 × 1080';
            final isPrimary = s['isPrimary'] == true;
            final thumb = (s['thumbnail'] as String?)?.trim();

            screens.add(RealScreenInfo(
              id: id.toString(),
              title: title.toString(),
              resolution: res.toString(),
              isPrimary: isPrimary,
              icon: LucideIcons.monitor,
              previewType: 'screen${i + 1}',
              thumbnail: (thumb != null && thumb.isNotEmpty) ? thumb : null,
            ));
          }

          final windows = <RealWindowInfo>[];
          final seenTitles = <String>{};

          for (final w in rawWindows) {
            if (w is! Map<String, dynamic>) continue;
            final title = (w['title'] ?? '').toString().trim();
            final app = (w['app'] ?? '').toString().trim();
            final thumb = (w['thumbnail'] as String?)?.trim();
            final pid = w['pid'];

            if (title.isEmpty || seenTitles.contains(title)) continue;

            final appLower = app.toLowerCase();
            final titleLower = title.toLowerCase();

            // 1. Never capture ProjectNBX itself (current process / app)
            if ((pid != null && pid == io.pid) ||
                appLower.contains('projectnbx') ||
                titleLower == 'projectnbx' ||
                titleLower.startsWith('projectnbx ')) {
              continue;
            }

            // 2. Ignore Windows internal background host processes and suspended UWP shells
            if (appLower.contains('textinputhost') ||
                appLower.contains('systemsettings') ||
                appLower.contains('shellexperiencehost') ||
                appLower.contains('startmenuexperiencehost') ||
                appLower.contains('searchhost') ||
                appLower.contains('searchapp') ||
                appLower.contains('searchui') ||
                appLower.contains('lockapp') ||
                appLower.contains('screenclippinghost') ||
                appLower.contains('securityhealth') ||
                appLower.contains('applicationframehost') ||
                titleLower.contains('experi') ||
                titleLower.contains('configura') ||
                titleLower.contains('input experience')) {
              continue;
            }

            seenTitles.add(title);

            final visuals = _resolveAppVisuals(app, title);
            windows.add(RealWindowInfo(
              title: title,
              app: app,
              icon: visuals.$1,
              color: visuals.$2,
              previewType: visuals.$3,
              thumbnail: (thumb != null && thumb.isNotEmpty) ? thumb : null,
            ));
          }

          if (screens.isNotEmpty || windows.isNotEmpty) {
            return (screens: screens, windows: windows);
          }
        }
      } catch (e) {
        debugPrint('[DesktopHardwareService] Erro ao obter fontes do sistema: $e');
      }
    }

    // Fast Fallback
    return (
      screens: const [
        RealScreenInfo(
          id: 'screen_1',
          title: 'Tela 1 (Principal)',
          resolution: '2560 × 1440',
          isPrimary: true,
          icon: LucideIcons.monitor,
          previewType: 'screen1',
        ),
        RealScreenInfo(
          id: 'screen_2',
          title: 'Tela 2',
          resolution: '3840 × 2160',
          isPrimary: false,
          icon: LucideIcons.monitor,
          previewType: 'screen2',
        ),
      ],
      windows: const [
        RealWindowInfo(
          title: 'YouTube - Vídeo ao Vivo',
          app: 'msedge.exe',
          icon: LucideIcons.video,
          color: Color(0xFFFF0000),
          previewType: 'youtube',
        ),
        RealWindowInfo(
          title: 'projectNBX - main.dart',
          app: 'studio64.exe',
          icon: LucideIcons.smartphone,
          color: Color(0xFF3DDC84),
          previewType: 'android_studio',
        ),
        RealWindowInfo(
          title: 'backend – GoLand',
          app: 'goland64.exe',
          icon: LucideIcons.code2,
          color: Color(0xFF00ADD8),
          previewType: 'goland',
        ),
        RealWindowInfo(
          title: 'GitHub Desktop',
          app: 'GitHubDesktop.exe',
          icon: LucideIcons.gitBranch,
          color: Color(0xFF8957E5),
          previewType: 'github',
        ),
      ],
    );
  }

  Future<List<RealScreenInfo>> getRealScreens() async {
    final res = await getAllSources();
    return res.screens;
  }

  Future<List<RealWindowInfo>> getRealWindows() async {
    final res = await getAllSources();
    return res.windows;
  }

  (IconData, Color, String) _resolveAppVisuals(String app, String title) {
    final lowerApp = app.toLowerCase();
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('youtube') || lowerApp.contains('youtube')) {
      return (LucideIcons.video, const Color(0xFFFF0000), 'youtube');
    }
    if (lowerApp.contains('studio64') || lowerTitle.contains('android studio')) {
      return (LucideIcons.smartphone, const Color(0xFF3DDC84), 'android_studio');
    }
    if (lowerApp.contains('goland') || lowerTitle.contains('goland')) {
      return (LucideIcons.code2, const Color(0xFF00ADD8), 'goland');
    }
    if (lowerApp.contains('code') || lowerTitle.contains('visual studio code')) {
      return (LucideIcons.code2, const Color(0xFF38BDF8), 'vscode');
    }
    if (lowerApp.contains('antigravity')) {
      return (LucideIcons.sparkles, const Color(0xFFC084FC), 'vscode');
    }
    if (lowerApp.contains('figma')) {
      return (LucideIcons.penTool, const Color(0xFFF24E1E), 'figma');
    }
    if (lowerApp.contains('github')) {
      return (LucideIcons.gitBranch, const Color(0xFF8957E5), 'github');
    }
    if (lowerApp.contains('whatsapp')) {
      return (LucideIcons.messageCircle, const Color(0xFF25D366), 'whatsapp');
    }
    if (lowerApp.contains('edge') || lowerApp.contains('msedge')) {
      return (LucideIcons.globe, const Color(0xFF38BDF8), 'chrome');
    }
    if (lowerApp.contains('chrome')) {
      return (LucideIcons.globe, const Color(0xFF4ADE80), 'chrome');
    }
    if (lowerApp.contains('discord')) {
      return (LucideIcons.messageSquare, const Color(0xFF5865F2), 'discord');
    }
    if (lowerApp.contains('spotify')) {
      return (LucideIcons.music, const Color(0xFF1DB954), 'spotify');
    }
    if (lowerApp.contains('signalrgb')) {
      return (LucideIcons.palette, const Color(0xFFEC4899), 'rgb');
    }
    if (lowerApp.contains('terminal') || lowerApp.contains('wt') || lowerApp.contains('powershell') || lowerApp.contains('cmd')) {
      return (LucideIcons.squareTerminal, const Color(0xFFA855F7), 'terminal');
    }
    if (lowerApp.contains('game') || lowerApp.contains('forza') || lowerApp.contains('steam')) {
      return (LucideIcons.gamepad2, const Color(0xFFEF4444), 'game');
    }

    return (LucideIcons.appWindow, const Color(0xFFF5CBA7), 'nbx');
  }
}
