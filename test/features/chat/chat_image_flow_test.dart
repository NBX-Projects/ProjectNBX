import 'dart:async';
import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:justtalking/core/network/api_client.dart';
import 'package:justtalking/features/chat/widgets/channel_chat_view.dart';
import 'package:justtalking/features/chat/widgets/components/image_lightbox_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// PNG 1x1 transparente válido (decodificável pelo ImageCompressor)
final Uint8List _kPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _FakeFilePicker extends FilePicker {
  PlatformFile? nextFile;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final file = nextFile;
    return file == null ? null : FilePickerResult([file]);
  }
}

class _SentMessage {
  final String? mediaUrl;
  final String? mediaType;
  const _SentMessage(this.mediaUrl, this.mediaType);
}

void main() {
  group('ApiClient.uploadMedia', () {
    test('retorna o payload do servidor em caso de sucesso', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, endsWith('/media/upload'));
          return http.Response(
            jsonEncode({'url': 'https://cdn/img_1.png'}),
            200,
          );
        }),
      );

      final res = await client.uploadMedia(bytes: _kPng, filename: 'a.png');

      expect(res['url'], 'https://cdn/img_1.png');
    });

    test('traduz 413 (proxy) para mensagem de tamanho', () async {
      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response('<html>413 Request Entity Too Large', 413),
        ),
      );

      expect(
        () => client.uploadMedia(bytes: _kPng, filename: 'a.gif'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('5 MB'),
          ),
        ),
      );
    });

    test('traduz falha de rede (Failed to fetch) para mensagem amigável', () {
      final client = ApiClient(
        client: MockClient((_) async => throw http.ClientException('Failed')),
      );

      expect(
        () => client.uploadMedia(bytes: _kPng, filename: 'a.png'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('Não foi possível enviar a imagem'),
              isNot(contains('ClientException')),
            ),
          ),
        ),
      );
    });

    test('propaga a mensagem de erro JSON do backend', () {
      final client = ApiClient(
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({'error': 'Formato inválido'}), 400),
        ),
      );

      expect(
        () => client.uploadMedia(bytes: _kPng, filename: 'a.png'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Formato inválido'),
          ),
        ),
      );
    });
  });

  group('ImageLightboxDialog salvar imagem', () {
    Future<void> pumpLightbox(
      WidgetTester tester, {
      required http.Client httpClient,
      required ImageFileSaver fileSaver,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageLightboxDialog(
              imageUrl: 'https://cdn.example.com/uploads/img_1.gif',
              httpClient: httpClient,
              fileSaver: fileSaver,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('baixa os bytes e salva com nome e MIME da resposta', (
      tester,
    ) async {
      Uint8List? savedBytes;
      String? savedName;
      String? savedMime;

      await pumpLightbox(
        tester,
        httpClient: MockClient(
          (_) async => http.Response.bytes(
            _kPng,
            200,
            headers: {'content-type': 'image/gif'},
          ),
        ),
        fileSaver:
            ({
              required Uint8List bytes,
              required String fileName,
              String mimeType = 'application/octet-stream',
            }) async {
              savedBytes = bytes;
              savedName = fileName;
              savedMime = mimeType;
              return true;
            },
      );

      await tester.tap(find.text('Salvar Imagem'));
      await tester.pumpAndSettle();

      expect(savedBytes, _kPng);
      expect(savedName, 'img_1.gif');
      expect(savedMime, 'image/gif');
      expect(find.text('Imagem salva com sucesso.'), findsOneWidget);
    });

    testWidgets('mostra erro amigável quando o download falha', (tester) async {
      var saverCalled = false;

      await pumpLightbox(
        tester,
        httpClient: MockClient((_) async => http.Response('not found', 404)),
        fileSaver:
            ({
              required Uint8List bytes,
              required String fileName,
              String mimeType = 'application/octet-stream',
            }) async {
              saverCalled = true;
              return true;
            },
      );

      await tester.tap(find.text('Salvar Imagem'));
      await tester.pumpAndSettle();

      expect(saverCalled, isFalse);
      expect(
        find.text('Não foi possível salvar a imagem. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('não mostra aviso quando o usuário cancela o diálogo', (
      tester,
    ) async {
      await pumpLightbox(
        tester,
        httpClient: MockClient((_) async => http.Response.bytes(_kPng, 200)),
        fileSaver:
            ({
              required Uint8List bytes,
              required String fileName,
              String mimeType = 'application/octet-stream',
            }) async => false,
      );

      await tester.tap(find.text('Salvar Imagem'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('ChannelChatView anexar e enviar imagem', () {
    late _FakeFilePicker picker;
    late TextEditingController messageController;
    late TextEditingController editController;
    late ScrollController scrollController;

    setUp(() {
      picker = _FakeFilePicker();
      FilePicker.platform = picker;
      messageController = TextEditingController();
      editController = TextEditingController();
      scrollController = ScrollController();
    });

    tearDown(() {
      messageController.dispose();
      editController.dispose();
      scrollController.dispose();
    });

    Future<void> pumpChat(
      WidgetTester tester, {
      Future<String?> Function(List<int> bytes, String filename)? onUpload,
      List<_SentMessage>? sent,
    }) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChannelChatView(
              isDark: true,
              activeChannelName: 'geral',
              channelKey: '1_geral',
              username: 'DevUser',
              messages: const [],
              messageController: messageController,
              editMessageController: editController,
              scrollController: scrollController,
              onSendMessage: (_, _) {},
              onSendMessageWithMedia: (_, _, {mediaUrl, mediaType}) =>
                  sent?.add(_SentMessage(mediaUrl, mediaType)),
              onUploadMedia: onUpload,
              onStartEditing: (_) {},
              onCancelEditing: () {},
              onSaveEditing: (_) {},
              onDeleteMessage: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DropTarget), findsOneWidget);
    }

    /// A compressão roda em isolate (compute), então precisa de tempo real
    Future<void> pickFile(WidgetTester tester, PlatformFile file) async {
      picker.nextFile = file;
      await tester.tap(find.byIcon(LucideIcons.plusCircle));
      for (var i = 0; i < 50; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.text(file.name).evaluate().isNotEmpty ||
            find.byType(SnackBar).evaluate().isNotEmpty) {
          break;
        }
      }
    }

    PlatformFile pngFile({String name = 'foto.png', int? size}) =>
        PlatformFile(name: name, size: size ?? _kPng.length, bytes: _kPng);

    testWidgets('anexa, envia e repassa URL e MIME corretos', (tester) async {
      final sent = <_SentMessage>[];
      List<int>? uploadedBytes;

      await pumpChat(
        tester,
        sent: sent,
        onUpload: (bytes, filename) async {
          uploadedBytes = bytes;
          return 'https://cdn/img_ok.png';
        },
      );

      await pickFile(tester, pngFile());
      expect(find.text('foto.png'), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pumpAndSettle();

      expect(uploadedBytes, isNotEmpty);
      expect(sent, hasLength(1));
      expect(sent.single.mediaUrl, 'https://cdn/img_ok.png');
      expect(sent.single.mediaType, 'image/png');
      expect(find.text('foto.png'), findsNothing);
    });

    testWidgets('falha no upload mantém o anexo e não envia a mensagem', (
      tester,
    ) async {
      final sent = <_SentMessage>[];

      await pumpChat(
        tester,
        sent: sent,
        onUpload: (_, _) async => throw Exception('Servidor indisponível'),
      );

      await pickFile(tester, pngFile());
      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pumpAndSettle();

      expect(sent, isEmpty);
      expect(
        find.text('Falha no upload da imagem: Servidor indisponível'),
        findsOneWidget,
      );
      expect(find.text('foto.png'), findsOneWidget);
    });

    testWidgets('upload sem URL não envia a mensagem', (tester) async {
      final sent = <_SentMessage>[];

      await pumpChat(tester, sent: sent, onUpload: (_, _) async => null);

      await pickFile(tester, pngFile());
      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pumpAndSettle();

      expect(sent, isEmpty);
      expect(
        find.text('Falha no upload: o servidor não retornou a URL da imagem.'),
        findsOneWidget,
      );
    });

    testWidgets('bloqueia envio duplicado enquanto o upload está em curso', (
      tester,
    ) async {
      final sent = <_SentMessage>[];
      final completer = Completer<String?>();
      var uploadCalls = 0;

      await pumpChat(
        tester,
        sent: sent,
        onUpload: (_, _) {
          uploadCalls++;
          return completer.future;
        },
      );

      await pickFile(tester, pngFile());
      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pump();
      await tester.tap(find.byIcon(LucideIcons.send));
      await tester.pump();

      expect(uploadCalls, 1);

      completer.complete('https://cdn/img_once.png');
      await tester.pumpAndSettle();

      expect(sent, hasLength(1));
    });

    testWidgets('rejeita arquivo acima de 5 MB sem anexar', (tester) async {
      await pumpChat(tester);

      await pickFile(
        tester,
        pngFile(name: 'enorme.png', size: ApiClient.maxUploadSizeBytes + 1),
      );

      expect(find.text('enorme.png'), findsNothing);
      expect(
        find.text('O arquivo excede o limite máximo permitido de 5 MB.'),
        findsOneWidget,
      );
    });

    testWidgets('rejeita formato não suportado', (tester) async {
      await pumpChat(tester);

      await pickFile(tester, pngFile(name: 'documento.pdf'));

      expect(find.text('documento.pdf'), findsNothing);
      expect(
        find.text(
          'Formato de imagem não suportado. Utilize PNG, JPG, WEBP, GIF ou BMP.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('botão de remover descarta o anexo', (tester) async {
      await pumpChat(tester);

      await pickFile(tester, pngFile());
      expect(find.text('foto.png'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chat_remove_attachment')));
      await tester.pumpAndSettle();

      expect(find.text('foto.png'), findsNothing);
    });

    testWidgets('não exibe informações de compressão ao usuário', (
      tester,
    ) async {
      await pumpChat(tester);

      await pickFile(tester, pngFile());

      expect(find.textContaining('otimizada'), findsNothing);
      expect(find.textContaining('compress'), findsNothing);
    });
  });
}
