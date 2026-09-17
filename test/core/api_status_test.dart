import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/api_status_controller.dart';
import 'package:projectnbx/core/widgets/api_offline_screen.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ApiStatusNotifier marks offline and online correctly', () {
    final client = ApiClient();
    final notifier = ApiStatusNotifier(client, autoCheck: false);

    expect(notifier.state.isOffline, isFalse);

    notifier.markOffline(message: 'Servidor 502 Bad Gateway', statusCode: 502);
    expect(notifier.state.isOffline, isTrue);
    expect(notifier.state.statusCode, equals(502));
    expect(notifier.state.errorMessage, contains('502'));

    notifier.markOnline();
    expect(notifier.state.isOffline, isFalse);
    expect(notifier.state.errorMessage, isNull);
  });

  test('ApiStatusNotifier checkStatus detects online and offline correctly', () async {
    final mockClientOnline = MockClient((request) async {
      return http.Response('{"status":"healthy"}', 200);
    });
    final onlineApiClient = ApiClient(client: mockClientOnline);
    final onlineNotifier = ApiStatusNotifier(onlineApiClient, autoCheck: false);

    final onlineResult = await onlineNotifier.checkStatus();
    expect(onlineResult, isTrue);
    expect(onlineNotifier.state.isOffline, isFalse);

    final mockClientOffline = MockClient((request) async {
      return http.Response('502 Bad Gateway', 502);
    });
    final offlineApiClient = ApiClient(client: mockClientOffline);
    final offlineNotifier = ApiStatusNotifier(offlineApiClient, autoCheck: false);

    final offlineResult = await offlineNotifier.checkStatus();
    expect(offlineResult, isFalse);
    expect(offlineNotifier.state.isOffline, isTrue);
  });

  testWidgets('ApiOfflineScreen renders title, status code and retry button', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiStatusProvider.overrideWith(
            (ref) => ApiStatusNotifier(ApiClient(), autoCheck: false)
              ..markOffline(message: 'Servidor 502', statusCode: 502),
          ),
          authControllerProvider.overrideWith(
            (ref) => AuthNotifier(ApiClient(), restore: false),
          ),
        ],
        child: const MaterialApp(
          home: ApiOfflineScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Serviços Temporariamente Indisponíveis'), findsOneWidget);
    expect(find.text('API: '), findsOneWidget);
    expect(find.text('WebSocket: '), findsOneWidget);
    expect(find.text('LiveKit: '), findsOneWidget);
    expect(find.textContaining('502 Bad Gateway'), findsOneWidget);
    expect(find.text('Desconectado'), findsOneWidget);
    expect(find.text('Indisponível'), findsOneWidget);
    expect(find.text('Tentar Novamente'), findsOneWidget);
    expect(find.text('Alterar Endereço do Servidor (Avançado)'), findsNothing);
  });
}
