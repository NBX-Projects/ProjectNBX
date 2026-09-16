import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/updater/update_models.dart';

class UpdateService {
  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca as informações da release mais recente no GitHub
  Future<ReleaseInfo?> fetchLatestRelease() async {
    const repo = AppConfig.githubRepo;
    final url = Uri.parse('https://api.github.com/repos/$repo/releases/latest');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ProjectNBX-App',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ReleaseInfo.fromJson(data);
      } else if (response.statusCode == 404) {
        // Nenhuma release encontrada ainda no repositório
        debugPrint('[UpdateService] Nenhuma release publicada encontrada.');
        return null;
      } else {
        throw Exception(
          'Falha ao verificar releases no GitHub: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Erro ao consultar releases: $e');
      rethrow;
    }
  }

  /// Compara se [latest] é estritamente mais recente que [current] seguindo SemVer
  static bool isNewerVersion(String latest, String current) {
    try {
      final vLatest = _parseVersion(latest);
      final vCurrent = _parseVersion(current);

      for (var i = 0; i < 3; i++) {
        if (vLatest[i] > vCurrent[i]) return true;
        if (vLatest[i] < vCurrent[i]) return false;
      }

      // Se major, minor e patch forem iguais, checa o build number
      if (vLatest.length > 3 && vCurrent.length > 3) {
        return vLatest[3] > vCurrent[3];
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parseVersion(String versionString) {
    var clean = versionString.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }

    // Separa build metadata se houver (ex: 1.0.0+2)
    var build = 0;
    if (clean.contains('+')) {
      final parts = clean.split('+');
      clean = parts[0];
      build = int.tryParse(parts[1]) ?? 0;
    }

    // Remove pre-release tags (ex: 1.0.0-beta)
    if (clean.contains('-')) {
      clean = clean.split('-')[0];
    }

    final segments = clean.split('.');
    final major = segments.isNotEmpty ? int.tryParse(segments[0]) ?? 0 : 0;
    final minor = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
    final patch = segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0;

    return [major, minor, patch, build];
  }

  /// Faz o download do arquivo com acompanhamento de progresso em stream
  Future<String> downloadFile({
    required String downloadUrl,
    required String filename,
    required void Function(int receivedBytes, int totalBytes) onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}${Platform.pathSeparator}$filename';
    final targetFile = File(filePath);

    if (await targetFile.exists()) {
      try {
        await targetFile.delete();
      } catch (_) {}
    }

    final request = http.Request('GET', Uri.parse(downloadUrl));
    request.headers['User-Agent'] = 'ProjectNBX-App';

    final response = await _client.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Falha no download do instalador: HTTP ${response.statusCode}',
      );
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;

    final sink = targetFile.openWrite();

    try {
      await response.stream.listen((chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        onProgress(receivedBytes, totalBytes);
      }).asFuture<void>();
    } finally {
      await sink.flush();
      await sink.close();
    }

    return targetFile.path;
  }

  /// Executa o instalador do Windows em modo desanexado e encerra a aplicação atual
  Future<void> launchWindowsInstaller(
    String installerPath, {
    bool silent = false,
  }) async {
    if (!Platform.isWindows) return;

    final args = silent ? ['/SILENT', '/NORESTART'] : <String>[];
    debugPrint(
      '[UpdateService] Disparando instalador Windows: $installerPath com args: $args',
    );

    await Process.start(
      installerPath,
      args,
      mode: ProcessStartMode.detached,
      runInShell: true,
    );

    // Encerra a aplicação para que o instalador do Inno Setup possa sobrescrever os arquivos
    await Future<void>.delayed(const Duration(milliseconds: 300));
    exit(0);
  }
}
