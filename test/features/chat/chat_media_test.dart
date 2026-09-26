import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/utils/image_compressor.dart';
import 'package:projectnbx/features/chat/models/chat_message.dart';
import 'package:projectnbx/features/chat/widgets/components/chat_bubble_components.dart';
import 'package:projectnbx/features/chat/widgets/components/confirm_delete_dialog.dart';
import 'package:projectnbx/features/chat/widgets/components/image_lightbox_dialog.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const List<int> _kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('ChatMessage Media Attachment Model Tests', () {
    test(
      'ChatMessage serializes and deserializes mediaUrl and mediaType correctly',
      () {
        final msg = ChatMessage(
          id: 'msg_media_1',
          author: 'Alice',
          authorColor: const Color(0xFFF5CBA7),
          content: 'Olha esta imagem',
          mediaUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
          mediaType: 'image/jpeg',
          timestamp: DateTime.utc(2026, 9, 21, 20, 0, 0),
        );

        final json = msg.toJson();
        expect(
          json['media_url'],
          'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        );
        expect(json['media_type'], 'image/jpeg');

        final fromJson = ChatMessage.fromJson(json);
        expect(fromJson.id, 'msg_media_1');
        expect(fromJson.content, 'Olha esta imagem');
        expect(
          fromJson.mediaUrl,
          'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        );
        expect(fromJson.mediaType, 'image/jpeg');
      },
    );

    test(
      'ChatMessage.fromApi handles payload with media_url and media_type',
      () {
        final apiPayload = {
          'id': 'msg_api_99',
          'author': {'username': 'Bob'},
          'content': 'Screenshot do bug',
          'media_url': 'http://localhost:8080/uploads/img_test.png',
          'media_type': 'image/png',
          'created_at': DateTime.now().toIso8601String(),
        };

        final msg = ChatMessage.fromApi(apiPayload, const Color(0xFF2D6A4F));
        expect(msg.id, 'msg_api_99');
        expect(msg.author, 'Bob');
        expect(msg.content, 'Screenshot do bug');
        expect(msg.mediaUrl, 'http://localhost:8080/uploads/img_test.png');
        expect(msg.mediaType, 'image/png');
      },
    );

    test('ChatMessage.copyWith updates media properties', () {
      const original = ChatMessage(
        id: '1',
        author: 'Charlie',
        authorColor: Colors.black,
        content: 'Sem imagem',
      );

      final updated = original.copyWith(
        mediaUrl: 'https://example.com/photo.webp',
        mediaType: 'image/webp',
      );

      expect(updated.mediaUrl, 'https://example.com/photo.webp');
      expect(updated.mediaType, 'image/webp');
      expect(updated.content, 'Sem imagem');
    });
  });

  group('WhatsAppChatBubble with Media Tests', () {
    testWidgets('renders message bubble with image and text content', (
      tester,
    ) async {
      final msg = ChatMessage(
        id: 'msg_test_bubble',
        author: 'Tester',
        authorColor: const Color(0xFFF5CBA7),
        content: 'Legenda da foto',
        mediaUrl: 'https://example.com/sample.png',
        mediaType: 'image/png',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WhatsAppChatBubble(
                  msg: msg,
                  isMine: false,
                  isDark: true,
                  isMobile: false,
                  screenWidth: 1024,
                  authorColor: const Color(0xFFF5CBA7),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tester'), findsOneWidget);
      expect(find.text('Legenda da foto'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('opens ImageLightboxDialog when clicking image attachment', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final msg = ChatMessage(
        id: 'msg_click_test',
        author: 'Dev',
        authorColor: const Color(0xFFF5CBA7),
        content: 'Clique para expandir',
        mediaUrl: 'https://example.com/sample.png',
        mediaType: 'image/png',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: Row(
                children: [
                  WhatsAppChatBubble(
                    msg: msg,
                    isMine: true,
                    isDark: true,
                    isMobile: false,
                    screenWidth: 1024,
                    authorColor: const Color(0xFFF5CBA7),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Clica na imagem anexada
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      await tester.tap(imageFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Confirma abertura do Lightbox
      expect(find.byType(ImageLightboxDialog), findsOneWidget);
      expect(find.text('Salvar Imagem'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      // Fecha o Lightbox
      await tester.tap(find.byIcon(LucideIcons.x), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ImageLightboxDialog), findsNothing);
    });
  });

  group('ImageLightboxDialog Widget Tests', () {
    testWidgets('renders lightbox with zoom interactive viewer and buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImageLightboxDialog(
              imageUrl: 'https://example.com/full_res.png',
              caption: 'Uma bela foto de teste',
              isDark: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Salvar Imagem'), findsOneWidget);
      expect(find.text('Uma bela foto de teste'), findsOneWidget);
      expect(find.byIcon(LucideIcons.download), findsOneWidget);
    });
  });

  group('ConfirmDeleteDialog Widget Tests', () {
    testWidgets('renders confirmation dialog with title, message and buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              title: 'Excluir Mensagem',
              message: 'Tem certeza de que deseja apagar?',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Excluir Mensagem'), findsOneWidget);
      expect(find.text('Tem certeza de que deseja apagar?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsNWidgets(2));
    });

    testWidgets('cancel button returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmDeleteDialog.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmDeleteDialog), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmDeleteDialog), findsNothing);
      expect(result, isFalse);
    });

    testWidgets('confirm button returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmDeleteDialog.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmDeleteDialog), findsOneWidget);

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmDeleteDialog), findsNothing);
      expect(result, isTrue);
    });
  });

  group('Media Upload Validation and Limits Tests', () {
    test('ImageCompressor validates allowed image formats', () {
      expect(ImageCompressor.isImageFile('photo.png'), isTrue);
      expect(ImageCompressor.isImageFile('PHOTO.PNG'), isTrue);
      expect(ImageCompressor.isImageFile('image.jpg'), isTrue);
      expect(ImageCompressor.isImageFile('picture.jpeg'), isTrue);
      expect(ImageCompressor.isImageFile('banner.webp'), isTrue);
      expect(ImageCompressor.isImageFile('anim.gif'), isTrue);
      expect(ImageCompressor.isImageFile('bitmap.bmp'), isTrue);

      expect(ImageCompressor.isImageFile('document.pdf'), isFalse);
      expect(ImageCompressor.isImageFile('script.sh'), isFalse);
      expect(ImageCompressor.isImageFile('malware.exe'), isFalse);
      expect(ImageCompressor.isImageFile('notes.txt'), isFalse);
      expect(ImageCompressor.isImageFile('archive.zip'), isFalse);
    });

    test('ApiClient validates 5 MB max size before sending', () async {
      final client = ApiClient();
      expect(ApiClient.maxUploadSizeBytes, 5 * 1024 * 1024);

      // Bytes excedendo 5 MB (5 MB + 1 byte)
      final hugeBytes = List<int>.filled(5 * 1024 * 1024 + 1, 0);

      expect(
        () => client.uploadMedia(bytes: hugeBytes, filename: 'large.png'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('5 MB'),
          ),
        ),
      );
    });
  });
}
