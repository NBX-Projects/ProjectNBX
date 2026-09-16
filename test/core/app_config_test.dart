import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    tearDown(() {
      AppConfig.setMockVersion(null);
    });

    test('Loads default configuration values correctly', () {
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.wsBaseUrl, isNotEmpty);
      expect(AppConfig.livekitUrl, isNotEmpty);
      expect(AppConfig.githubRepo, equals('NBX-Projects/ProjectNBX'));
    });

    test('Handles mock version and fallback version', () {
      AppConfig.setMockVersion('2.5.0');
      expect(AppConfig.version, equals('2.5.0'));

      AppConfig.setMockVersion(null);
      expect(AppConfig.version, equals('1.0.0'));
    });

    test('Correctly identifies dev vs prod environments', () {
      if (AppConfig.environment.contains('dev')) {
        expect(AppConfig.isDev, isTrue);
        expect(AppConfig.isProd, isFalse);
      } else {
        expect(AppConfig.isDev, isFalse);
        expect(AppConfig.isProd, isTrue);
      }
    });
  });
}
