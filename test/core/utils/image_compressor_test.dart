import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:projectnbx/core/utils/image_compressor.dart';

void main() {
  group('ImageCompressor Tests', () {
    test('isImageFile correctly identifies image and non-image extensions', () {
      expect(ImageCompressor.isImageFile('foto.png'), isTrue);
      expect(ImageCompressor.isImageFile('PHOTO.JPEG'), isTrue);
      expect(ImageCompressor.isImageFile('imagem.webp'), isTrue);
      expect(ImageCompressor.isImageFile('anim.gif'), isTrue);
      expect(ImageCompressor.isImageFile('arquivo.bmp'), isTrue);

      expect(ImageCompressor.isImageFile('documento.pdf'), isFalse);
      expect(ImageCompressor.isImageFile('script.sh'), isFalse);
      expect(ImageCompressor.isImageFile('executavel.exe'), isFalse);
      expect(ImageCompressor.isImageFile('texto.txt'), isFalse);
    });

    test(
      'compress resizes large image and produces high compression JPEG',
      () async {
        // Cria imagem sintética grande de 2400x1600 em formato BMP descompactado (~11.5 MB)
        final rawImage = img.Image(width: 2400, height: 1600);
        for (int y = 0; y < 1600; y++) {
          for (int x = 0; x < 2400; x++) {
            rawImage.setPixelRgb(x, y, (x % 255), (y % 255), ((x + y) % 255));
          }
        }
        final rawBmpBytes = Uint8List.fromList(img.encodeBmp(rawImage));
        expect(rawBmpBytes.length, greaterThan(1000000)); // Mais de 1 MB

        final result = await ImageCompressor.compress(
          bytes: rawBmpBytes,
          filename: 'foto_grande.bmp',
          quality: 75,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        // Verifica redimensionamento proporcional
        expect(result.width, lessThanOrEqualTo(1920));
        expect(result.height, lessThanOrEqualTo(1080));
        // Verifica extensão convertida para jpg
        expect(result.filename.endsWith('.jpg'), isTrue);
        expect(result.mimeType, 'image/jpeg');
        // Verifica redução expressiva de tamanho (> 70% de compressão)
        expect(result.compressedSize, lessThan(result.originalSize));
        expect(result.compressionPercentage, greaterThan(70.0));
      },
    );

    test(
      'compress gracefully handles corrupted/invalid image bytes with fallback',
      () async {
        final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
        final result = await ImageCompressor.compress(
          bytes: invalidBytes,
          filename: 'corrompido.jpg',
        );

        expect(result.bytes, equals(invalidBytes));
        expect(result.compressedSize, equals(invalidBytes.length));
        expect(result.filename, 'corrompido.jpg');
      },
    );
  });
}
