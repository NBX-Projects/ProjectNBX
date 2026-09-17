import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Perfis de qualidade alvo para compartilhamento de tela
class ScreenQualityProfile {
  final String label;
  final String description;
  final int width;
  final int height;
  final int maxFps;
  final int maxBitrate; // em bps

  const ScreenQualityProfile({
    required this.label,
    required this.description,
    required this.width,
    required this.height,
    required this.maxFps,
    required this.maxBitrate,
  });

  static const low = ScreenQualityProfile(
    label: 'Econômico',
    description: '720p @ 20 FPS (Ideal para código e texto)',
    width: 1280,
    height: 720,
    maxFps: 20,
    maxBitrate: 1200000, // 1.2 Mbps
  );

  static const medium = ScreenQualityProfile(
    label: 'Balanceado',
    description: '1080p @ 30 FPS (Padrão para apresentações)',
    width: 1920,
    height: 1080,
    maxFps: 30,
    maxBitrate: 3000000, // 3.0 Mbps
  );

  static const high = ScreenQualityProfile(
    label: 'Alta Fluidez',
    description: '1080p @ 60 FPS (Para vídeos e jogos)',
    width: 1920,
    height: 1080,
    maxFps: 60,
    maxBitrate: 6000000, // 6.0 Mbps
  );

  static const List<ScreenQualityProfile> all = [low, medium, high];
}

/// Representação de uma fonte de captura (Monitor ou Janela)
class ScreenSource {
  final String id;
  final String name;
  final bool isWindow;
  final Uint8List? thumbnail;

  const ScreenSource({
    required this.id,
    required this.name,
    required this.isWindow,
    this.thumbnail,
  });
}

/// Interface abstrata para listagem e captura de fontes de tela
abstract class ScreenCaptureSource {
  Future<List<ScreenSource>> getSources({bool includeWindows = true});
  Future<MediaStream> capture(ScreenSource source, ScreenQualityProfile profile);
  Future<void> stop(MediaStream stream);
}

/// Implementação padrão usando flutter_webrtc DesktopCapturer
class DesktopScreenCaptureSource implements ScreenCaptureSource {
  @override
  Future<List<ScreenSource>> getSources({bool includeWindows = true}) async {
    final types = <SourceType>[
      SourceType.Screen,
      if (includeWindows) SourceType.Window,
    ];

    try {
      final rawSources = await desktopCapturer.getSources(types: types);
      return rawSources.map((s) {
        return ScreenSource(
          id: s.id,
          name: s.name,
          isWindow: s.type == SourceType.Window,
          thumbnail: s.thumbnail,
        );
      }).toList();
    } catch (_) {
      // Fallback genérico para plataformas que não suportam desktopCapturer nativo diretamente
      return [
        const ScreenSource(
          id: 'entire_screen',
          name: 'Tela Principal',
          isWindow: false,
        ),
      ];
    }
  }

  @override
  Future<MediaStream> capture(ScreenSource source, ScreenQualityProfile profile) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'chromeMediaSource': source.isWindow ? 'window' : 'desktop',
          'chromeMediaSourceId': source.id,
          'maxWidth': profile.width,
          'maxHeight': profile.height,
          'maxFrameRate': profile.maxFps,
        },
        'optional': <dynamic>[],
      },
    };

    try {
      return await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
    } catch (_) {
      // Fallback sem id específico
      return await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'width': profile.width,
          'height': profile.height,
          'frameRate': profile.maxFps,
        },
        'audio': false,
      });
    }
  }

  @override
  Future<void> stop(MediaStream stream) async {
    for (final track in stream.getTracks()) {
      track.stop();
    }
    await stream.dispose();
  }
}
