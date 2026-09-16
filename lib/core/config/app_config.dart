import 'package:package_info_plus/package_info_plus.dart';

enum Environment { dev, prod }

class AppConfig {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'ProjectNBX Dev',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  static const String livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'ws://localhost:7880',
  );

  static const String githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: 'NBX-Projects/ProjectNBX',
  );

  static const String _defaultVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static String? _resolvedVersion;
  static String? _mockVersion;

  /// Retorna a versão da aplicação (resolvida dinamicamente via PackageInfo quando disponível, ou definida via build/fallback)
  static String get version {
    if (_mockVersion != null) {
      return _mockVersion!;
    }
    final defaultVer = _defaultVersion.trim().replaceAll(RegExp(r'^[vV]'), '');
    if (defaultVer.isNotEmpty && defaultVer != '1.0.0') {
      return defaultVer;
    }
    final resolved = _resolvedVersion?.trim().replaceAll(RegExp(r'^[vV]'), '');
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    return defaultVer.isNotEmpty ? defaultVer : '1.0.0';
  }

  static bool get isDev =>
      environment.toLowerCase().startsWith('dev') ||
      environment.toLowerCase() == 'development';

  static bool get isProd => !isDev;

  /// Inicializa metadados do pacote (versão, build number) em runtime
  static Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _resolvedVersion = info.version;
      }
    } catch (_) {
      // Fallback para versão padrão caso ocorra erro (ex: ambiente de teste de widget simples)
    }
  }

  /// Permite sobrescrever a versão para cenários de testes unitários
  static void setMockVersion(String? mockVersion) {
    _mockVersion = mockVersion;
    _resolvedVersion = mockVersion;
  }
}
