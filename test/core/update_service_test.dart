import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/updater/update_controller.dart';
import 'package:projectnbx/core/updater/update_models.dart';
import 'package:projectnbx/core/updater/update_service.dart';

void main() {
  group('UpdateService Version Comparison Tests', () {
    test('Correctly identifies newer major, minor, and patch versions', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(UpdateService.isNewerVersion('v1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewerVersion('v1.2.3', 'v1.2.2'), isTrue);
    });

    test('Correctly identifies older or equal versions', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('0.9.9', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('v1.0.0', '1.0.0'), isFalse);
    });

    test('Handles build numbers and prerelease suffixes', () {
      expect(UpdateService.isNewerVersion('1.0.0+2', '1.0.0+1'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.0+1', '1.0.0+2'), isFalse);
      expect(UpdateService.isNewerVersion('1.1.0-beta', '1.0.0'), isTrue);
    });
  });

  group('ReleaseInfo JSON Parsing & Asset Filtering Tests', () {
    test('Parses GitHub Release response and finds assets correctly', () {
      final json = {
        'tag_name': 'v1.2.0',
        'name': 'Release 1.2.0',
        'body': 'Novas funcionalidades incríveis',
        'html_url': 'https://github.com/NBX-Projects/ProjectNBX/releases/tag/v1.2.0',
        'published_at': '2026-09-15T20:00:00Z',
        'assets': [
          {
            'name': 'ProjectNBX-Setup-v1.2.0-windows.exe',
            'browser_download_url': 'https://github.com/download/setup.exe',
            'size': 45000000,
          },
          {
            'name': 'ProjectNBX-v1.2.0-android.apk',
            'browser_download_url': 'https://github.com/download/app.apk',
            'size': 32000000,
          },
        ],
      };

      final release = ReleaseInfo.fromJson(json);

      expect(release.version, equals('1.2.0'));
      expect(release.tagName, equals('v1.2.0'));
      expect(release.name, equals('Release 1.2.0'));
      expect(release.body, contains('Novas funcionalidades'));
      expect(release.assets.length, equals(2));

      final winAsset = release.windowsInstallerAsset;
      expect(winAsset, isNotNull);
      expect(winAsset!.name, equals('ProjectNBX-Setup-v1.2.0-windows.exe'));

      final apkAsset = release.androidApkAsset;
      expect(apkAsset, isNotNull);
      expect(apkAsset!.name, equals('ProjectNBX-v1.2.0-android.apk'));
    });
  });

  group('UpdateController Tests', () {
    tearDown(() {
      AppConfig.setMockVersion(null);
    });

    test('Changes state to available when a newer version is released', () async {
      AppConfig.setMockVersion('1.0.0');

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          final payload = jsonEncode({
            'tag_name': 'v1.1.0',
            'name': 'Release 1.1.0',
            'body': 'Update changelog',
            'html_url': 'https://github.com/releases/v1.1.0',
            'assets': [
              {
                'name': 'ProjectNBX-Setup-v1.1.0.exe',
                'browser_download_url': 'https://github.com/setup.exe',
                'size': 1000,
              },
            ],
          });
          return http.Response(payload, 200);
        }
        return http.Response('Not found', 404);
      });

      final service = UpdateService(client: mockClient);
      final controller = UpdateController(service);

      expect(controller.state.status, equals(UpdateStatus.idle));

      await controller.checkForUpdates(silent: false);

      expect(controller.state.status, equals(UpdateStatus.available));
      expect(controller.state.isUpdateAvailable, isTrue);
      expect(controller.state.latestRelease?.version, equals('1.1.0'));
      expect(controller.state.isDismissed, isFalse);

      controller.dismissBanner();
      expect(controller.state.isDismissed, isTrue);
    });

    test('Changes state to upToDate when currently on the latest version', () async {
      AppConfig.setMockVersion('1.1.0');

      final mockClient = MockClient((request) async {
        final payload = jsonEncode({
          'tag_name': 'v1.1.0',
          'name': 'Release 1.1.0',
          'body': 'No update needed',
          'html_url': 'https://github.com/releases/v1.1.0',
          'assets': <Map<String, dynamic>>[],
        });
        return http.Response(payload, 200);
      });

      final service = UpdateService(client: mockClient);
      final controller = UpdateController(service);

      await controller.checkForUpdates(silent: false);

      expect(controller.state.status, equals(UpdateStatus.upToDate));
      expect(controller.state.isUpdateAvailable, isFalse);
    });
  });
}
