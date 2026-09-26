import 'package:flutter/foundation.dart';

/// Resultado da recodificação feita pelo codec nativo do navegador
class BrowserEncodedImage {
  final Uint8List bytes;
  final int width;
  final int height;
  final bool wasResized;

  const BrowserEncodedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.wasResized,
  });
}

/// Fora da Web não há codec de navegador: o ImageCompressor usa o isolate.
Future<BrowserEncodedImage?> encodeInBrowser({
  required Uint8List bytes,
  required String targetMimeType,
  required double quality,
  required int maxWidth,
  required int maxHeight,
}) async => null;
