import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/auth/screens/login_screen.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/create_server_dialog.dart';
import 'package:projectnbx/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen renders and toggles theme and tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: ProjectNBXApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Login screen elements
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('ProjectNBX'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar Conta'), findsOneWidget);

    // Toggle Theme (Dark to Light)
    expect(find.text('Tema Claro'), findsOneWidget);
    await tester.tap(find.text('Tema Claro'));
    await tester.pumpAndSettle();

    // Now it should show 'Tema Escuro' in the toggle
    expect(find.text('Tema Escuro'), findsOneWidget);

    // Switch to Register tab
    await tester.tap(find.text('Criar Conta'));
    await tester.pumpAndSettle();

    expect(find.text('Nome de Usuário'), findsOneWidget);
    expect(find.text('CRIAR CONTA'), findsOneWidget);
  });

  testWidgets('HomeScreen renders empty state when no servers and opens CreateServerDialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthNotifier(ApiClient(), restore: false)
              ..state = const AuthState(
                user: UserModel(
                  id: 'test-1',
                  username: 'DevUser',
                  email: 'dev@nbx.com',
                ),
                token: 'dummy-token',
              ),
          ),
          serversControllerProvider.overrideWith(
            (ref) => ServersNotifier(ApiClient(), autoLoad: false)
              ..state = const ServersState(servers: []),
          ),
        ],
        child: const ProjectNBXApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NBX PROJECT'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('MEUS SERVIDORES'), findsOneWidget);
    expect(find.text('NOVO SERVIDOR'), findsAtLeastNWidgets(1));

    // Open create server dialog via the card or header button
    await tester.tap(find.text('NOVO SERVIDOR').first);
    await tester.pumpAndSettle();

    expect(find.byType(CreateServerDialog), findsOneWidget);
    expect(find.text('Criar seu Servidor'), findsOneWidget);
    expect(find.text('NOME DO SERVIDOR'), findsOneWidget);
  });

  testWidgets('HomeScreen renders channels and workspace when server is selected', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testServer = ServerModel(
      id: 'srv-1',
      name: 'Dev Hub',
      ownerId: 'test-1',
      channels: [
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
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthNotifier(ApiClient(), restore: false)
              ..state = const AuthState(
                user: UserModel(
                  id: 'test-1',
                  username: 'DevUser',
                  email: 'dev@nbx.com',
                ),
                token: 'dummy-token',
              ),
          ),
          serversControllerProvider.overrideWith(
            (ref) => ServersNotifier(ApiClient(), autoLoad: false)
              ..state = const ServersState(
                servers: [testServer],
                selectedServerId: 'srv-1',
                selectedChannelId: 'c1',
              ),
          ),
        ],
        child: const ProjectNBXApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('SERVIDORES FAVORITOS'), findsOneWidget);
    expect(find.text('MAIS UTILIZADOS NO MÊS'), findsOneWidget);
    expect(find.text('MAIS AMIGOS EM CHAMADA'), findsOneWidget);
    expect(find.text('Dev Hub'), findsAtLeastNWidgets(1));
    expect(find.text('PRÓXIMOS EVENTOS'), findsOneWidget);
  });
}
