import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Resultado do processo de compressão de imagem
class CompressedImageResult {
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final int originalSize;
  final int compressedSize;
  final int width;
  final int height;

  const CompressedImageResult({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.originalSize,
    required this.compressedSize,
    required this.width,
    required this.height,
  });

  /// Percentual de redução de tamanho obtido com a compressão
  double get compressionPercentage {
    if (originalSize <= 0) return 0.0;
    final saved = originalSize - compressedSize;
    if (saved <= 0) return 0.0;
    return (saved / originalSize) * 100.0;
  }
}

/// Parâmetros transmitidos para o worker de compressão isolado
class _CompressPayload {
  final Uint8List bytes;
  final String filename;
  final int quality;
  final int maxWidth;
  final int maxHeight;

  const _CompressPayload({
    required this.bytes,
    required this.filename,
    required this.quality,
    required this.maxWidth,
    required this.maxHeight,
  });
}

/// Serviço utilitário de compressão de alta eficiência para imagens
class ImageCompressor {
  /// Extensões de imagem suportadas pelo app
  static const Set<String> supportedExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
    '.bmp',
  };

  /// Valida se o nome do arquivo possui uma extensão de imagem suportada
  static bool isImageFile(String filename) {
    final lower = filename.toLowerCase();
    return supportedExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Comprime a imagem reduzindo resolução se necessário e aplicando quantização de alta eficiência.
  ///
  /// Executa fora da thread principal de UI via [compute] para evitar travamentos visuais.
  static Future<CompressedImageResult> compress({
    required Uint8List bytes,
    required String filename,
    int quality = 75,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    final payload = _CompressPayload(
      bytes: bytes,
      filename: filename,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    if (kIsWeb) {
      return _compressWorker(payload);
    }

    try {
      return await compute(_compressWorker, payload);
    } catch (_) {
      // Fallback local se a inicialização de isolate falhar
      return _compressWorker(payload);
    }
  }

  /// Função de execução da compressão (adequada para Isolate/Compute)
  static CompressedImageResult _compressWorker(_CompressPayload payload) {
    final originalSize = payload.bytes.length;
    final lowerName = payload.filename.toLowerCase();

    // 1. Tenta decodificar a imagem
    final decoded = img.decodeImage(payload.bytes);
    if (decoded == null) {
      // Falha na decodificação: retorna original como fallback seguro
      return CompressedImageResult(
        bytes: payload.bytes,
        filename: payload.filename,
        mimeType: _guessMimeType(payload.filename),
        originalSize: originalSize,
        compressedSize: originalSize,
        width: 0,
        height: 0,
      );
    }

    // 2. Se for um GIF animado com múltiplos frames, preservamos a animação original
    if (decoded.numFrames > 1 || lowerName.endsWith('.gif')) {
      return CompressedImageResult(
        bytes: payload.bytes,
        filename: payload.filename,
        mimeType: 'image/gif',
        originalSize: originalSize,
        compressedSize: originalSize,
        width: decoded.width,
        height: decoded.height,
      );
    }

    // 3. Redimensionamento proporcional se exceder maxWidth ou maxHeight
    img.Image processed = decoded;
    if (processed.width > payload.maxWidth ||
        processed.height > payload.maxHeight) {
      final double widthRatio = payload.maxWidth / processed.width;
      final double heightRatio = payload.maxHeight / processed.height;
      final double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      final targetW = (processed.width * ratio).round();
      final targetH = (processed.height * ratio).round();

      processed = img.copyResize(
        processed,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.average,
      );
    }

    // 4. Codificação de alta compressão
    Uint8List compressedBytes;
    String finalFilename = payload.filename;
    String finalMimeType = 'image/jpeg';

    final isPng = lowerName.endsWith('.png');
    final hasAlpha = processed.hasAlpha;

    if (isPng && hasAlpha) {
      // Se for PNG com canal alfa transparente ativo, comprime como PNG otimizado
      compressedBytes = Uint8List.fromList(
        img.encodePng(processed, level: 6, filter: img.PngFilter.paeth),
      );
      finalMimeType = 'image/png';
    } else {
      // Converte para JPEG com qualidade otimizada (alta taxa de compressão)
      compressedBytes = Uint8List.fromList(
        img.encodeJpg(processed, quality: payload.quality),
      );
      finalMimeType = 'image/jpeg';

      // Ajusta extensão se o original era .png/.bmp mas foi convertido para .jpg compacto
      if (!lowerName.endsWith('.jpg') && !lowerName.endsWith('.jpeg')) {
        final dotIndex = finalFilename.lastIndexOf('.');
        if (dotIndex != -1) {
          finalFilename = '${finalFilename.substring(0, dotIndex)}.jpg';
        } else {
          finalFilename = '$finalFilename.jpg';
        }
      }
    }

    // Se a imagem não foi redimensionada e por alguma razão o arquivo resultante ficou maior, mantém o menor
    final wasResized =
        processed.width != decoded.width || processed.height != decoded.height;
    if (compressedBytes.length > originalSize && !wasResized) {
      return CompressedImageResult(
        bytes: payload.bytes,
        filename: payload.filename,
        mimeType: _guessMimeType(payload.filename),
        originalSize: originalSize,
        compressedSize: originalSize,
        width: decoded.width,
        height: decoded.height,
      );
    }

    return CompressedImageResult(
      bytes: compressedBytes,
      filename: finalFilename,
      mimeType: finalMimeType,
      originalSize: originalSize,
      compressedSize: compressedBytes.length,
      width: processed.width,
      height: processed.height,
    );
  }

  static String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
