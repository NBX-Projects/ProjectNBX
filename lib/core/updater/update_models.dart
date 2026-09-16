enum UpdateStatus {
  idle,
  checking,
  available,
  upToDate,
  downloading,
  readyToInstall,
  error,
}

class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int sizeBytes;

  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      sizeBytes: json['size'] as int? ?? 0,
    );
  }
}

class ReleaseInfo {
  final String tagName;
  final String version;
  final String name;
  final String body;
  final String htmlUrl;
  final DateTime? publishedAt;
  final List<ReleaseAsset> assets;

  const ReleaseInfo({
    required this.tagName,
    required this.version,
    required this.name,
    required this.body,
    required this.htmlUrl,
    this.publishedAt,
    required this.assets,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final rawTag = json['tag_name'] as String? ?? '';
    final cleanVersion = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
    final rawAssets = json['assets'] as List<dynamic>? ?? [];
    final assets = rawAssets
        .whereType<Map<String, dynamic>>()
        .map(ReleaseAsset.fromJson)
        .toList();

    DateTime? pubDate;
    if (json['published_at'] != null) {
      pubDate = DateTime.tryParse(json['published_at'].toString());
    }

    return ReleaseInfo(
      tagName: rawTag,
      version: cleanVersion,
      name: json['name'] as String? ?? rawTag,
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      publishedAt: pubDate,
      assets: assets,
    );
  }

  /// Retorna o asset do instalador Windows (.exe) se disponível
  ReleaseAsset? get windowsInstallerAsset {
    return assets.cast<ReleaseAsset?>().firstWhere(
      (asset) =>
          asset != null &&
          asset.name.toLowerCase().endsWith('.exe') &&
          asset.name.toLowerCase().contains('setup'),
      orElse: () => assets.cast<ReleaseAsset?>().firstWhere(
        (asset) => asset != null && asset.name.toLowerCase().endsWith('.exe'),
        orElse: () => null,
      ),
    );
  }

  /// Retorna o asset do APK Android (.apk) se disponível
  ReleaseAsset? get androidApkAsset {
    return assets.cast<ReleaseAsset?>().firstWhere(
      (asset) => asset != null && asset.name.toLowerCase().endsWith('.apk'),
      orElse: () => null,
    );
  }
}

class UpdateState {
  final UpdateStatus status;
  final ReleaseInfo? latestRelease;
  final String currentVersion;
  final double downloadProgress; // 0.0 a 1.0
  final int bytesDownloaded;
  final int totalBytes;
  final String? downloadedFilePath;
  final String? errorMessage;
  final bool isDismissed;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.latestRelease,
    required this.currentVersion,
    this.downloadProgress = 0.0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.downloadedFilePath,
    this.errorMessage,
    this.isDismissed = false,
  });

  bool get isUpdateAvailable =>
      status == UpdateStatus.available ||
      status == UpdateStatus.downloading ||
      status == UpdateStatus.readyToInstall;

  UpdateState copyWith({
    UpdateStatus? status,
    ReleaseInfo? latestRelease,
    String? currentVersion,
    double? downloadProgress,
    int? bytesDownloaded,
    int? totalBytes,
    String? downloadedFilePath,
    String? errorMessage,
    bool? isDismissed,
  }) {
    return UpdateState(
      status: status ?? this.status,
      latestRelease: latestRelease ?? this.latestRelease,
      currentVersion: currentVersion ?? this.currentVersion,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
