import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/updater/update_models.dart';
import 'package:projectnbx/core/updater/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>((ref) {
      final service = ref.watch(updateServiceProvider);
      return UpdateController(service);
    });

class UpdateController extends StateNotifier<UpdateState> {
  final UpdateService _service;

  UpdateController(this._service)
    : super(UpdateState(currentVersion: AppConfig.version));

  /// Verifica se há uma nova versão disponível
  Future<void> checkForUpdates({bool silent = true}) async {
    // Atualiza versão corrente
    state = state.copyWith(
      status: UpdateStatus.checking,
      currentVersion: AppConfig.version,
      errorMessage: null,
    );

    try {
      final latest = await _service.fetchLatestRelease();

      if (latest == null) {
        state = state.copyWith(status: UpdateStatus.upToDate);
        return;
      }

      final hasUpdate = UpdateService.isNewerVersion(
        latest.version,
        AppConfig.version,
      );

      if (hasUpdate) {
        state = state.copyWith(
          status: UpdateStatus.available,
          latestRelease: latest,
          isDismissed: false,
        );
      } else {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          latestRelease: latest,
        );
      }
    } catch (e) {
      debugPrint('[UpdateController] Erro na verificação: $e');
      if (!silent) {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: 'Não foi possível verificar atualizações: $e',
        );
      } else {
        state = state.copyWith(status: UpdateStatus.idle);
      }
    }
  }

  /// Inicia o fluxo de download e instalação
  Future<void> downloadAndInstall({bool silentInstaller = false}) async {
    final release = state.latestRelease;
    if (release == null) return;

    if (!kIsWeb && Platform.isWindows) {
      final asset = release.windowsInstallerAsset;
      if (asset == null) {
        // Se não houver asset específico, abre a página de release no navegador
        await openReleasePage();
        return;
      }

      state = state.copyWith(
        status: UpdateStatus.downloading,
        downloadProgress: 0.0,
        bytesDownloaded: 0,
        totalBytes: asset.sizeBytes,
        errorMessage: null,
      );

      try {
        final filePath = await _service.downloadFile(
          downloadUrl: asset.downloadUrl,
          filename: asset.name,
          onProgress: (received, total) {
            final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
            state = state.copyWith(
              downloadProgress: progress,
              bytesDownloaded: received,
              totalBytes: total,
            );
          },
        );

        state = state.copyWith(
          status: UpdateStatus.readyToInstall,
          downloadedFilePath: filePath,
        );

        // Executa o instalador do Windows
        await _service.launchWindowsInstaller(
          filePath,
          silent: silentInstaller,
        );
      } catch (e) {
        debugPrint('[UpdateController] Erro ao baixar atualização: $e');
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: 'Erro durante o download da atualização: $e',
        );
      }
    } else if (!kIsWeb && Platform.isAndroid) {
      final apkAsset = release.androidApkAsset;
      final targetUrl = apkAsset?.downloadUrl ?? release.htmlUrl;
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // Web ou outras plataformas: abre a página de release
      await openReleasePage();
    }
  }

  /// Abre a página de release no GitHub
  Future<void> openReleasePage() async {
    final url =
        state.latestRelease?.htmlUrl ??
        'https://github.com/${AppConfig.githubRepo}/releases';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Oculta temporariamente o banner de atualização
  void dismissBanner() {
    state = state.copyWith(isDismissed: true);
  }
}
