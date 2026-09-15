import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/localization/app_language.dart';
import 'package:projectnbx/core/localization/app_strings.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_theme.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/servers/models/server_workspace_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          methodCall,
        ) async {
          if (methodCall.method == 'isMaximized') return false;
          return null;
        });
  });

  group('AppLanguage & AppStrings', () {
    test('AppLanguage properties', () {
      expect(AppLanguage.pt.code, 'pt');
      expect(AppLanguage.pt.name, 'Português (Brasil)');
      expect(AppLanguage.pt.flag, '🇧🇷');

      expect(AppLanguage.en.code, 'en');
      expect(AppLanguage.en.name, 'English (US)');
      expect(AppLanguage.en.flag, '🇺🇸');
    });

    test('AppStrings translations for PT and EN', () {
      const ptStrings = AppStrings(AppLanguage.pt);
      expect(ptStrings.isPt, isTrue);
      expect(ptStrings.appTitle, 'NBX PROJECT');
      expect(ptStrings.online, 'Online');
      expect(ptStrings.idle, 'Ausente');
      expect(ptStrings.dnd, 'Não Perturbe');
      expect(ptStrings.connected, 'CONECTADO');
      expect(ptStrings.active, 'ATIVO');
      expect(ptStrings.cancel, 'Cancelar');
      expect(ptStrings.save, 'Salvar');
      expect(ptStrings.close, 'Fechar');
      expect(ptStrings.navHome, 'Início');
      expect(ptStrings.navFavorites, 'Favoritos');
      expect(ptStrings.navTrending, 'Em Alta');
      expect(ptStrings.navDMs, 'Amigos & Conversas');
      expect(ptStrings.navVoice, 'Salas de Voz');
      expect(ptStrings.navExplore, 'Explorar');
      expect(ptStrings.navSettings, 'Configurações');
      expect(ptStrings.hubSubtitle(3, 5), '3 comunidades · 5 em chamadas agora');
      expect(ptStrings.serverCreatedSuccess('Devs'), 'Servidor "Devs" criado com sucesso!');

      const enStrings = AppStrings(AppLanguage.en);
      expect(enStrings.isPt, isFalse);
      expect(enStrings.appTitle, 'NBX PROJECT');
      expect(enStrings.online, 'Online');
      expect(enStrings.idle, 'Away');
      expect(enStrings.dnd, 'Do Not Disturb');
      expect(enStrings.connected, 'CONNECTED');
      expect(enStrings.active, 'ACTIVE');
      expect(enStrings.cancel, 'Cancel');
      expect(enStrings.save, 'Save');
      expect(enStrings.close, 'Close');
      expect(enStrings.navHome, 'Home');
      expect(enStrings.navFavorites, 'Favorites');
      expect(enStrings.navTrending, 'Trending');
      expect(enStrings.navDMs, 'Friends & DMs');
      expect(enStrings.navVoice, 'Voice Lounges');
      expect(enStrings.navExplore, 'Explore');
      expect(enStrings.navSettings, 'Settings');
      expect(enStrings.hubSubtitle(3, 5), '3 communities · 5 in calls now');
      expect(enStrings.serverCreatedSuccess('Devs'), 'Server "Devs" created successfully!');
    });

    test('LocaleNotifier toggles and sets language', () {
      final notifier = LocaleNotifier();
      expect(notifier.state, AppLanguage.pt);

      notifier.toggleLanguage();
      expect(notifier.state, AppLanguage.en);

      notifier.toggleLanguage();
      expect(notifier.state, AppLanguage.pt);

      notifier.setLanguage(AppLanguage.en);
      expect(notifier.state, AppLanguage.en);
    });
  });

  group('AppColors, AppTheme & ThemeModeNotifier', () {
    test('AppColors palette definitions and getBannerGradient', () {
      expect(AppColors.darkCanvas, isNotNull);
      expect(AppColors.darkSurface, isNotNull);
      expect(AppColors.darkPrimary, isNotNull);
      expect(AppColors.darkSage, isNotNull);
      expect(AppColors.lightCanvas, isNotNull);
      expect(AppColors.lightSurface, isNotNull);
      expect(AppColors.lightPrimary, isNotNull);
      expect(AppColors.lightSage, isNotNull);
      expect(AppColors.serverAccentPalette.length, 5);

      // getBannerGradient tests
      final grad0 = AppColors.getBannerGradient(0);
      expect(grad0, AppColors.bannerPresets[0]);

      final gradFallback = AppColors.getBannerGradient(-1, 'custom_srv_id');
      expect(gradFallback.length, 3);

      final gradDefault = AppColors.getBannerGradient(999);
      expect(gradDefault, AppColors.bannerPresets[0]);
    });

    test('AppTheme dark and light configurations', () {
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.primary, AppColors.darkPrimary);

      final light = AppTheme.lightTheme;
      expect(light.brightness, Brightness.light);
      expect(light.colorScheme.primary, AppColors.lightPrimary);
    });

    test('ThemeModeNotifier toggles and sets theme', () {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, ThemeMode.dark);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.light);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.dark);

      notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
    });
  });

  group('WindowControls Widget', () {
    testWidgets('Renders WindowControls buttons and reacts to hover and clicks', (
      WidgetTester tester,
    ) async {
      int minimizeCount = 0;
      int maximizeCount = 0;
      int closeCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('window_manager'), (
            methodCall,
          ) async {
            if (methodCall.method == 'isMaximized') return false;
            if (methodCall.method == 'minimize') {
              minimizeCount++;
              return null;
            }
            if (methodCall.method == 'maximize') {
              maximizeCount++;
              return null;
            }
            if (methodCall.method == 'close') {
              closeCount++;
              return null;
            }
            return null;
          });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: WindowControls(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica presença dos botões pelos ícones
      expect(find.byIcon(LucideIcons.minus), findsOneWidget);
      expect(find.byIcon(LucideIcons.square), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      // Clica em minimizar
      await tester.tap(find.byIcon(LucideIcons.minus));
      await tester.pumpAndSettle();
      expect(minimizeCount, 1);

      // Clica em maximizar
      await tester.tap(find.byIcon(LucideIcons.square));
      await tester.pumpAndSettle();
      expect(maximizeCount, 1);

      // Clica em fechar
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(closeCount, 1);
    });
  });

  group('ApiClient REST & BaseUrl', () {
    test('setCustomBaseUrl manipulates baseUrl correctly', () {
      ApiClient.setCustomBaseUrl('192.168.1.50:9000');
      expect(ApiClient.baseUrl, 'http://192.168.1.50:9000/api');

      ApiClient.setCustomBaseUrl('https://api.myproject.com/');
      expect(ApiClient.baseUrl, 'https://api.myproject.com/api');

      ApiClient.setCustomBaseUrl(null);
      expect(ApiClient.baseUrl.contains(':8080'), isTrue);
    });

    test('AuthToken setter and getter', () {
      final client = ApiClient();
      expect(client.authToken, isNull);
      client.setAuthToken('token-123');
      expect(client.authToken, 'token-123');
      client.setAuthToken(null);
      expect(client.authToken, isNull);
    });

    test('login success and failure with MockClient', () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['email'] == 'valid@nbx.com') {
            return http.Response(
              jsonEncode({
                'token': 'jwt-abc',
                'user': {'id': '1', 'username': 'Valid', 'email': 'valid@nbx.com'},
              }),
              200,
            );
          } else {
            return http.Response(
              jsonEncode({'error': 'Senha incorreta'}),
              401,
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(client: mock);

      final res = await api.login('valid@nbx.com', 'secret');
      expect(res.token, 'jwt-abc');
      expect(res.user.username, 'Valid');
      expect(api.authToken, 'jwt-abc');

      expect(
        () => api.login('invalid@nbx.com', 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('register success and failure with MockClient', () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/auth/register')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['username'] == 'NewUser') {
            return http.Response(
              jsonEncode({
                'token': 'reg-token',
                'user': {'id': '2', 'username': 'NewUser', 'email': 'new@nbx.com'},
              }),
              201,
            );
          } else {
            return http.Response(
              jsonEncode({'error': 'Nome de usuário em uso'}),
              400,
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(client: mock);
      final res = await api.register('NewUser', 'new@nbx.com', 'pass');
      expect(res.token, 'reg-token');

      expect(
        () => api.register('Duplicate', 'd@nbx.com', 'pass'),
        throwsA(isA<Exception>()),
      );
    });

    test('getServers and createServer', () async {
      final mock = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/servers')) {
          return http.Response(
            jsonEncode([
              {'id': 'srv-1', 'name': 'Dev Community'},
            ]),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path.endsWith('/servers')) {
          return http.Response(
            jsonEncode({'id': 'srv-2', 'name': 'Gamer Hub'}),
            201,
          );
        }
        return http.Response('Error', 500);
      });

      final api = ApiClient(client: mock);
      final servers = await api.getServers();
      expect(servers.length, 1);
      expect(servers.first['name'], 'Dev Community');

      final created = await api.createServer('Gamer Hub');
      expect(created?['name'], 'Gamer Hub');
    });

    test('getChannels, getMessages, updateMessage, deleteMessage', () async {
      final mock = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/channels') && !request.url.path.contains('/messages')) {
          return http.Response(
            jsonEncode([{'id': 'ch-1', 'name': 'geral'}]),
            200,
          );
        }
        if (request.method == 'GET' && request.url.path.contains('/messages')) {
          return http.Response(
            jsonEncode([{'id': 'msg-1', 'content': 'Olá mundo'}]),
            200,
          );
        }
        if (request.method == 'PUT' && request.url.path.contains('/messages/msg-1')) {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        if (request.method == 'DELETE' && request.url.path.contains('/messages/msg-1')) {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Error', 500);
      });

      final api = ApiClient(client: mock);
      final channels = await api.getChannels('srv-1');
      expect(channels.length, 1);

      final messages = await api.getMessages('srv-1', 'ch-1');
      expect(messages.length, 1);

      final updated = await api.updateMessage('srv-1', 'ch-1', 'msg-1', 'Novo texto');
      expect(updated, isTrue);

      final deleted = await api.deleteMessage('srv-1', 'ch-1', 'msg-1');
      expect(deleted, isTrue);
    });

    test('Members, Invites, Search and Voice Token', () async {
      final mock = MockClient((request) async {
        if (request.url.path.contains('/members')) {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([{'id': 'u-1', 'username': 'Member1'}]),
              200,
            );
          }
          if (request.method == 'POST') {
            return http.Response(jsonEncode({'user_id': 'u-2'}), 200);
          }
          if (request.method == 'DELETE') {
            return http.Response(jsonEncode({'success': true}), 200);
          }
        }
        if (request.url.path.contains('/join')) {
          return http.Response(jsonEncode({'server_id': 'srv-joined'}), 200);
        }
        if (request.url.path.contains('/invites')) {
          if (request.method == 'POST') {
            return http.Response(jsonEncode({'code': 'INV-123'}), 200);
          }
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([{'code': 'INV-123'}]),
              200,
            );
          }
          if (request.method == 'DELETE') {
            return http.Response(jsonEncode({'success': true}), 200);
          }
        }
        if (request.url.path.contains('/users/search')) {
          return http.Response(
            jsonEncode([{'id': 'u-9', 'username': 'Result'}]),
            200,
          );
        }
        if (request.url.path.contains('/voice/token')) {
          return http.Response(
            jsonEncode({'token': 'livekit-jwt-voice'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final api = ApiClient(client: mock);

      final members = await api.getServerMembers('srv-1');
      expect(members.length, 1);

      final added = await api.addServerMember('srv-1', username: 'Member2');
      expect(added?['user_id'], 'u-2');

      final removed = await api.removeServerMember('srv-1', 'u-2');
      expect(removed, isTrue);

      final joined = await api.joinServer('INV-123');
      expect(joined?['server_id'], 'srv-joined');

      final invite = await api.createInvite('srv-1', maxAgeSeconds: 3600, maxUses: 5);
      expect(invite?['code'], 'INV-123');

      final invites = await api.getServerInvites('srv-1');
      expect(invites.length, 1);

      final deletedInvite = await api.deleteInvite('srv-1', 'INV-123');
      expect(deletedInvite, isTrue);

      final users = await api.searchUsers('Result');
      expect(users.length, 1);

      final voice = await api.getVoiceToken('channel-voice-1');
      expect(voice['token'], 'livekit-jwt-voice');
    });
  });

  group('WebSocketClient lifecycle & messaging', () {
    test('WebSocketClient initialization and disconnect', () {
      final api = ApiClient();
      final ws = WebSocketClient(api);

      expect(ws.isConnected, isFalse);
      expect(ws.eventStream, isNotNull);

      // Sending an event before connection should queue it
      ws.sendEvent('CHAT_MESSAGE', {'content': 'Olá'});

      ws.disconnect();
      expect(ws.isConnected, isFalse);

      ws.dispose();
    });

    test('ServerWorkspaceEnums values', () {
      expect(ServerViewMode.values, contains(ServerViewMode.home));
      expect(ServerViewMode.values, contains(ServerViewMode.channel));
      expect(ServerSidebarTab.values, contains(ServerSidebarTab.canais));
      expect(ServerSidebarTab.values, contains(ServerSidebarTab.membros));
      expect(ServerSidebarTab.values, contains(ServerSidebarTab.resumo));
    });

    test('WebSocketClient connects to server, exchanges messages and handles events', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.transform(WebSocketTransformer()).listen((WebSocket socket) {
        socket.listen((data) {
          final decoded = jsonDecode(data.toString()) as Map<String, dynamic>;
          if (decoded['type'] == 'PING') {
            socket.add(jsonEncode({'type': 'PONG', 'payload': {'reply': 'pong'}}));
          }
        });
      });

      ApiClient.setCustomBaseUrl('127.0.0.1:${server.port}');
      final api = ApiClient()..setAuthToken('dummy-jwt');
      final ws = WebSocketClient(api);
      addTearDown(() => ws.dispose());

      expect(ws.isConnected, isFalse);

      // Queue an event before connecting
      ws.sendEvent('PRE_CONNECT', {'data': 123}, serverId: 'srv-1', channelId: 'ch-1');

      await ws.connect(serverId: 'srv-1');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(ws.isConnected, isTrue);

      // Send ping and receive pong via eventStream
      final receivedFuture = ws.eventStream.firstWhere((e) => e['type'] == 'PONG');
      ws.sendEvent('PING', <String, dynamic>{});

      final receivedEvent = await receivedFuture.timeout(const Duration(seconds: 2));
      expect(receivedEvent['type'], 'PONG');

      ws.disconnect();
      expect(ws.isConnected, isFalse);
    });
  });
}
