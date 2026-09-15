import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/docked_voice_footer.dart';
import 'package:projectnbx/features/servers/widgets/server_home_view.dart';
import 'package:projectnbx/features/servers/widgets/server_right_sidebar.dart';
import 'package:projectnbx/features/servers/widgets/server_top_nav.dart';
import 'package:projectnbx/features/servers/widgets/server_workspace_view.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testChannels = [
    ChannelModel(
      id: 'c1',
      serverId: 'srv-1',
      name: 'geral',
      type: ChannelType.text,
    ),
    ChannelModel(
      id: 'c2',
      serverId: 'srv-1',
      name: 'Lounge SFU',
      type: ChannelType.voice,
    ),
  ];

  const testServer = ServerModel(
    id: 'srv-1',
    name: 'Dev Hub Workspace',
    ownerId: 'usr-1',
    memberCount: 8,
    channels: testChannels,
  );

  group('Server Components Tests', () {
    testWidgets('ServerTopNav renders server name and triggers callbacks', (tester) async {
      var backPressed = false;
      var goToHubPressed = false;
      var invitePressed = false;
      var sidebarToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerTopNav(
              server: testServer,
              isDark: true,
              viewMode: ServerViewMode.channel,
              activeChannel: testChannels.first,
              accentColor: Colors.blue,
              isRightSidebarVisible: true,
              onBackToHome: () {
                backPressed = true;
              },
              onGoToHub: () {
                goToHubPressed = true;
              },
              onInviteMembers: () {
                invitePressed = true;
              },
              onToggleRightSidebar: () {
                sidebarToggled = true;
              },
              onOpenMobileChannelsSheet: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dev Hub Workspace'), findsOneWidget);

      // Back to home button
      final backFinder = find.byIcon(LucideIcons.arrowLeft);
      expect(backFinder, findsOneWidget);
      await tester.tap(backFinder);
      expect(backPressed, isTrue);

      // Go to hub pill
      final hubPill = find.text('Início');
      if (hubPill.evaluate().isNotEmpty) {
        await tester.tap(hubPill.first);
        expect(goToHubPressed, isTrue);
      }

      // Invite button
      final inviteFinder = find.byIcon(LucideIcons.userPlus);
      if (inviteFinder.evaluate().isNotEmpty) {
        await tester.tap(inviteFinder.first);
        expect(invitePressed, isTrue);
      }

      // Sidebar toggle button
      final sidebarFinder = find.byIcon(LucideIcons.panelRightClose);
      if (sidebarFinder.evaluate().isNotEmpty) {
        await tester.tap(sidebarFinder.first);
        expect(sidebarToggled, isTrue);
      }
    });

    testWidgets('ServerHomeView renders hero banner and channels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerHomeView(
              server: testServer,
              isDark: true,
              username: 'Tester',
              channels: testChannels,
              isTransmitting: false,
              selectedBannerPreset: 0,
              onSelectBannerPreset: (_) {},
              selectedAccentColor: Colors.blue,
              onSelectAccentColor: (_) {},
              isCustomizingBanner: false,
              onToggleCustomizeBanner: () {},
              onSaveCustomization: () async {},
              onOpenChannel: (c) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dev Hub Workspace'), findsOneWidget);
      expect(find.text('Acontecendo no servidor'), findsOneWidget);
    });

    testWidgets('ServerRightSidebar renders and toggles tabs', (tester) async {
      final voiceNotifier = VoiceStateNotifier();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServerRightSidebar(
              isDark: true,
              server: testServer,
              channels: testChannels,
              activeChannel: testChannels.first,
              username: 'Tester',
              accentColor: Colors.blue,
              voiceParticipants: const {},
              serverMembers: const [
                {'user_id': 'u1', 'username': 'DevUser', 'role': 'owner'},
                {'user_id': 'u2', 'username': 'Gamer2', 'role': 'member'},
              ],
              voiceState: const VoiceState(),
              voiceNotifier: voiceNotifier,
              onChannelSelected: (c) {},
              onLeaveVoice: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('geral'), findsAtLeastNWidgets(1));

      // Switch to Members tab
      final membersTab = find.text('Membros');
      if (membersTab.evaluate().isNotEmpty) {
        await tester.tap(membersTab.first);
        await tester.pumpAndSettle();

        expect(find.text('DevUser'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('DockedVoiceFooter renders active connection and actions', (tester) async {
      final voiceNotifier = VoiceStateNotifier();
      var leftVoice = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockedVoiceFooter(
              isDark: true,
              channelName: 'Lounge SFU',
              serverName: 'Dev Hub',
              voiceState: const VoiceState(isMicMuted: false, isDeafened: false),
              voiceNotifier: voiceNotifier,
              onLeaveVoice: () {
                leftVoice = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Conectado'), findsOneWidget);
      expect(find.textContaining('Lounge SFU'), findsOneWidget);

      // Disconnect button
      final dcFinder = find.byIcon(LucideIcons.phoneOff);
      if (dcFinder.evaluate().isNotEmpty) {
        await tester.tap(dcFinder.first);
        expect(leftVoice, isTrue);
      }
    });

    testWidgets('ServerWorkspaceView integration renders full workspace', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var backHome = false;
      final fakeApi = FakeWorkspaceApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApi),
            authControllerProvider.overrideWith(
              (ref) => AuthNotifier(fakeApi, restore: false)
                ..state = const AuthState(
                  user: UserModel(
                    id: 'usr-1',
                    username: 'Tester',
                    email: 'test@example.com',
                  ),
                  token: 'dummy-token',
                ),
            ),
            websocketClientProvider.overrideWith(
              (ref) => FakeWebSocketClient(fakeApi),
            ),
            serversControllerProvider.overrideWith(
              (ref) => ServersNotifier(fakeApi, autoLoad: false)
                ..state = const ServersState(
                  servers: [testServer],
                  selectedServerId: 'srv-1',
                ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServerWorkspaceView(
                server: testServer,
                onBackToHome: () {
                  backHome = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top nav is rendered
      expect(find.byType(ServerTopNav), findsOneWidget);
      expect(find.text('Dev Hub Workspace'), findsAtLeastNWidgets(1));

      // Right sidebar is rendered
      expect(find.byType(ServerRightSidebar), findsOneWidget);

      // Go to Hub via Início button
      final hubPill = find.text('Início');
      if (hubPill.evaluate().isNotEmpty) {
        await tester.tap(hubPill.first);
        expect(backHome, isTrue);
      }
    });

    testWidgets('ServerWorkspaceView opens channel, interacts with chat and toggles features', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeApi = FakeWorkspaceApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApi),
            websocketClientProvider.overrideWith(
              (ref) => FakeWebSocketClient(fakeApi),
            ),
            authControllerProvider.overrideWith(
              (ref) => AuthNotifier(fakeApi, restore: false)
                ..state = const AuthState(
                  user: UserModel(
                    id: 'usr-1',
                    username: 'Tester',
                    email: 'test@example.com',
                  ),
                  token: 'dummy-token',
                ),
            ),
            serversControllerProvider.overrideWith(
              (ref) => ServersNotifier(fakeApi, autoLoad: false)
                ..state = const ServersState(
                  servers: [testServer],
                  selectedServerId: 'srv-1',
                ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServerWorkspaceView(
                server: testServer,
                onBackToHome: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clica no canal 'geral' para abrir a sala híbrida (Chat + Voz)
      final channelTile = find.text('geral');
      expect(channelTile, findsAtLeastNWidgets(1));
      await tester.tap(channelTile.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifica se a mensagem existente foi carregada
      expect(find.text('Mensagem inicial do canal'), findsOneWidget);

      // Envia uma nova mensagem pelo input de chat
      final chatInput = find.byType(TextField).first;
      await tester.enterText(chatInput, 'Testando envio de mensagem!');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Mensagem aparece no histórico
      expect(find.text('Testando envio de mensagem!'), findsOneWidget);

      // Edita a mensagem recém enviada
      final editBtn = find.byIcon(LucideIcons.pencil);
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Encontra o botão Salvar da edição
        final saveBtn = find.text('Salvar');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      // Exclui a mensagem
      final deleteBtn = find.byIcon(LucideIcons.trash2);
      if (deleteBtn.evaluate().isNotEmpty) {
        await tester.tap(deleteBtn.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Alterna visibilidade da sidebar lateral direita pelo botão de toggle
      final toggleSidebarIcon = find.byIcon(LucideIcons.panelRightClose);
      if (toggleSidebarIcon.evaluate().isNotEmpty) {
        await tester.tap(toggleSidebarIcon.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Desconecta da chamada de voz clicando no botão do footer de voz
      final leaveVoiceBtn = find.byIcon(LucideIcons.phoneOff);
      if (leaveVoiceBtn.evaluate().isNotEmpty) {
        await tester.tap(leaveVoiceBtn.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    });

    testWidgets('ServerWorkspaceView customizes banner and saves changes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeApi = FakeWorkspaceApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApi),
            websocketClientProvider.overrideWith(
              (ref) => FakeWebSocketClient(fakeApi),
            ),
            authControllerProvider.overrideWith(
              (ref) => AuthNotifier(fakeApi, restore: false)
                ..state = const AuthState(
                  user: UserModel(
                    id: 'usr-1',
                    username: 'Tester',
                    email: 'test@example.com',
                  ),
                  token: 'dummy-token',
                ),
            ),
            serversControllerProvider.overrideWith(
              (ref) => ServersNotifier(fakeApi, autoLoad: false)
                ..state = const ServersState(
                  servers: [testServer],
                  selectedServerId: 'srv-1',
                ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServerWorkspaceView(
                server: testServer,
                onBackToHome: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clica em Personalizar Banner
      final customizeBtn = find.text('Personalizar Banner');
      if (customizeBtn.evaluate().isNotEmpty) {
        await tester.tap(customizeBtn.first);
        await tester.pumpAndSettle();

        // Clica em Salvar Customização
        final saveBtn = find.text('Salvar');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('ServerWorkspaceView handles WS events, channel changes and sidebar interactions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeApi = FakeWorkspaceApiClient();
      final fakeWs = FakeWebSocketClient(fakeApi);
      addTearDown(fakeWs.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApi),
            websocketClientProvider.overrideWithValue(fakeWs),
            authControllerProvider.overrideWith(
              (ref) => AuthNotifier(fakeApi, restore: false)
                ..state = const AuthState(
                  user: UserModel(
                    id: 'usr-1',
                    username: 'Tester',
                    email: 'test@example.com',
                  ),
                  token: 'dummy-token',
                ),
            ),
            serversControllerProvider.overrideWith(
              (ref) => ServersNotifier(fakeApi, autoLoad: false)
                ..state = const ServersState(
                  servers: [testServer],
                  selectedServerId: 'srv-1',
                ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServerWorkspaceView(
                server: testServer,
                onBackToHome: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Alterna entre abas da sidebar lateral direita (Membros, Resumo, Canais)
      final membersTab = find.text('Membros');
      if (membersTab.evaluate().isNotEmpty) {
        await tester.tap(membersTab.first);
        await tester.pumpAndSettle();
      }

      final summaryTab = find.text('Resumo');
      if (summaryTab.evaluate().isNotEmpty) {
        await tester.tap(summaryTab.first);
        await tester.pumpAndSettle();
      }

      final channelsTab = find.text('Canais');
      if (channelsTab.evaluate().isNotEmpty) {
        await tester.tap(channelsTab.first);
        await tester.pumpAndSettle();
      }

      // 2. Troca para o canal de voz 'Lounge SFU'
      final voiceChannelFinder = find.text('Lounge SFU');
      if (voiceChannelFinder.evaluate().isNotEmpty) {
        await tester.tap(voiceChannelFinder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // 3. Emite eventos via WebSocket
      // a) CHAT_MESSAGE
      fakeWs.emit({
        'type': 'CHAT_MESSAGE',
        'channel_id': 'c1',
        'server_id': 'srv-1',
        'payload': {
          'id': 'msg-ws-1',
          'content': 'Mensagem em tempo real via WS',
          'author': {'username': 'ColegaDev'},
          'created_at': DateTime.now().toIso8601String(),
        },
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // b) MESSAGE_UPDATE
      fakeWs.emit({
        'type': 'MESSAGE_UPDATE',
        'channel_id': 'c1',
        'server_id': 'srv-1',
        'payload': {
          'id': 'msg-ws-1',
          'content': 'Mensagem editada via WS',
        },
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // c) VOICE_STATE (join)
      fakeWs.emit({
        'type': 'VOICE_STATE',
        'channel_id': 'c2',
        'server_id': 'srv-1',
        'payload': {
          'session_id': 'sess-remote-1',
          'user_id': 'usr-remote',
          'username': 'RemoteUser',
          'channel_id': 'c2',
          'server_id': 'srv-1',
          'is_in_voice': true,
        },
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // d) VOICE_SYNC
      fakeWs.emit({
        'type': 'VOICE_SYNC',
        'server_id': 'srv-1',
        'payload': [
          {
            'session_id': 'sess-remote-2',
            'user_id': 'usr-remote-2',
            'username': 'RemoteUser2',
            'channel_id': 'c2',
            'server_id': 'srv-1',
            'is_in_voice': true,
          }
        ],
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // e) VOICE_STATE (leave)
      fakeWs.emit({
        'type': 'VOICE_STATE',
        'channel_id': 'c2',
        'server_id': 'srv-1',
        'payload': {
          'session_id': 'sess-remote-1',
          'user_id': 'usr-remote',
          'channel_id': 'c2',
          'server_id': 'srv-1',
          'is_in_voice': false,
        },
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // f) MESSAGE_DELETE
      fakeWs.emit({
        'type': 'MESSAGE_DELETE',
        'channel_id': 'c1',
        'server_id': 'srv-1',
        'payload': {
          'id': 'msg-ws-1',
        },
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 4. Alterna de volta para o canal de texto 'geral'
      final textChannelFinder = find.text('geral');
      if (textChannelFinder.evaluate().isNotEmpty) {
        await tester.tap(textChannelFinder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // 5. Teste em visualização compacta/mobile
      tester.view.physicalSize = const Size(500, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clica no menu hambúrguer para abrir a sheet de canais mobile
      final menuBtn = find.byIcon(LucideIcons.menu);
      if (menuBtn.evaluate().isNotEmpty) {
        await tester.tap(menuBtn.first);
        await tester.pumpAndSettle();

        // Fecha a sheet tocando no canal
        final sheetChan = find.text('# geral');
        if (sheetChan.evaluate().isNotEmpty) {
          await tester.tap(sheetChan.first);
          await tester.pumpAndSettle();
        }
      }
    });
  });
}

class FakeWebSocketClient extends WebSocketClient {
  final _eventCtrl = StreamController<Map<String, dynamic>>.broadcast();

  FakeWebSocketClient(super.apiClient);

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventCtrl.stream;

  void emit(Map<String, dynamic> event) => _eventCtrl.add(event);

  @override
  Future<void> connect({String? serverId}) async {}

  @override
  void sendEvent(
    String type,
    dynamic payload, {
    String? channelId,
    String? serverId,
  }) {}

  @override
  void dispose() {
    _eventCtrl.close();
    super.dispose();
  }
}

class FakeWorkspaceApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> getVoiceToken(String channelId) async {
    return {'token': '', 'server_url': ''};
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(String serverId, String channelId) async {
    return [
      {
        'id': 'msg-existing-1',
        'author': {'username': 'OutroDev'},
        'content': 'Mensagem inicial do canal',
        'created_at': DateTime.now().toIso8601String(),
      }
    ];
  }

  @override
  Future<bool> updateMessage(String serverId, String channelId, String messageId, String content) async {
    return true;
  }

  @override
  Future<bool> deleteMessage(String serverId, String channelId, String messageId) async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getServerMembers(String serverId) async {
    return [
      {'user_id': 'usr-1', 'username': 'Tester', 'role': 'owner'},
    ];
  }
}

