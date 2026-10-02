import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:justtalking/core/utils/image_compressor_browser_stub.dart'
    show BrowserEncodedImage;
import 'package:web/web.dart' as web;

export 'package:justtalking/core/utils/image_compressor_browser_stub.dart'
    show BrowserEncodedImage;

/// Redimensiona e recodifica a imagem com o codec nativo do navegador
/// (createImageBitmap + OffscreenCanvas), sem bloquear a thread da UI.
///
/// Retorna `null` se o navegador não suportar as APIs ou a decodificação falhar.
Future<BrowserEncodedImage?> encodeInBrowser({
  required Uint8List bytes,
  required String targetMimeType,
  required double quality,
  required int maxWidth,
  required int maxHeight,
}) async {
  web.ImageBitmap? bitmap;
  try {
    final source = web.Blob([bytes.toJS].toJS);
    bitmap = await web.window.createImageBitmap(source).toDart;

    final srcWidth = bitmap.width;
    final srcHeight = bitmap.height;
    if (srcWidth <= 0 || srcHeight <= 0) return null;

    var targetWidth = srcWidth;
    var targetHeight = srcHeight;
    if (srcWidth > maxWidth || srcHeight > maxHeight) {
      final widthRatio = maxWidth / srcWidth;
      final heightRatio = maxHeight / srcHeight;
      final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;
      targetWidth = (srcWidth * ratio).round();
      targetHeight = (srcHeight * ratio).round();
    }

    final canvas = web.OffscreenCanvas(targetWidth, targetHeight);
    final context =
        canvas.getContext('2d') as web.OffscreenCanvasRenderingContext2D?;
    if (context == null) return null;

    context.imageSmoothingQuality = 'high';
    context.drawImage(bitmap, 0, 0, targetWidth, targetHeight);

    final blob = await canvas
        .convertToBlob(
          web.ImageEncodeOptions(type: targetMimeType, quality: quality),
        )
        .toDart;
    final buffer = await blob.arrayBuffer().toDart;

    return BrowserEncodedImage(
      bytes: buffer.toDart.asUint8List(),
      width: targetWidth,
      height: targetHeight,
      wasResized: targetWidth != srcWidth || targetHeight != srcHeight,
    );
  } catch (e) {
    debugPrint('[ImageCompressor] Codec do navegador indisponível: $e');
    return null;
  } finally {
    bitmap?.close();
  }
}
