import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justtalking/core/network/api_client.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/auth/models/user_model.dart';
import 'package:justtalking/features/auth/screens/login_screen.dart';
import 'package:justtalking/features/servers/controllers/servers_controller.dart';
import 'package:justtalking/features/servers/models/channel_model.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:justtalking/features/servers/widgets/create_server_dialog.dart';
import 'package:justtalking/main.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen renders and toggles tabs and inputs', (
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
    expect(find.text('NBX Projects'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar Conta'), findsOneWidget);

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

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('MEUS SERVIDORES'), findsOneWidget);

    // Open create server dialog via the plus button
    final addServerFinder = find.byIcon(LucideIcons.plus);
    if (addServerFinder.evaluate().isNotEmpty) {
      await tester.tap(addServerFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(CreateServerDialog), findsOneWidget);
      expect(find.text('Criar seu Servidor'), findsOneWidget);
    }
  });

  testWidgets('HomeScreen renders Hub and server cards when servers exist', (
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
              ),
          ),
        ],
        child: const ProjectNBXApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Dev Hub'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'HomeScreen handles transient collapsed web viewport (1x1) without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1, 1);
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
          ],
          child: const ProjectNBXApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'UserStatusChip on mobile hides name and status text, showing only photo/avatar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
                    id: 'test-mobile',
                    username: 'Taui',
                    name: 'Taui Lima',
                    email: 'taui@nbx.com',
                    status: 'online',
                  ),
                  token: 'dummy-token',
                ),
            ),
          ],
          child: const ProjectNBXApp(),
        ),
      );
      await tester.pumpAndSettle();

      // On mobile topbar, the avatar initial "T" is shown
      expect(find.text('T'), findsOneWidget);

      // Name and "Online" must NOT appear in the top bar chip
      expect(find.text('Taui'), findsNothing);
      expect(find.text('Online'), findsNothing);
    },
  );

  testWidgets(
    'UserStatusChip on desktop displays name and online status text',
    (WidgetTester tester) async {
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
                    id: 'test-desktop',
                    username: 'Taui',
                    name: 'Taui Lima',
                    email: 'taui@nbx.com',
                    status: 'online',
                  ),
                  token: 'dummy-token',
                ),
            ),
          ],
          child: const ProjectNBXApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Taui'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    },
  );
}
