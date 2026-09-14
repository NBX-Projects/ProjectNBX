import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/widgets/invite_member_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testServer = ServerModel(
    id: 'srv-1',
    name: 'Dev Hub',
    ownerId: 'usr-1',
    channels: [],
  );

  testWidgets(
    'InviteMemberDialog renders invite code, copy button, and settings',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/members')) {
          return http.Response(
            jsonEncode([
              {
                'user_id': 'usr-1',
                'role': 'owner',
                'user': {
                  'id': 'usr-1',
                  'username': 'DevOwner',
                  'email': 'owner@nbx.com',
                },
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/invites') && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'code': 'k9X2mQa',
                'server_id': 'srv-1',
                'is_expired': false,
                'is_exhausted': false,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final mockApiClient = ApiClient(client: mockClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(mockApiClient),
            authControllerProvider.overrideWith(
              (ref) =>
                  AuthNotifier(mockApiClient, restore: false)
                    ..state = const AuthState(
                      user: UserModel(
                        id: 'usr-1',
                        username: 'DevOwner',
                        email: 'owner@nbx.com',
                      ),
                      token: 'token',
                    ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InviteMemberDialog(server: testServer)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dialog header
      expect(find.text('Convidar para Dev Hub'), findsOneWidget);
      expect(find.text('LINK DE CONVITE'), findsOneWidget);

      // Verify code rendered
      expect(find.text('k9X2mQa'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);

      // Verify settings toggle
      final settingsToggleFinder = find.text('Editar validade do link');
      expect(settingsToggleFinder, findsOneWidget);
      await tester.ensureVisible(settingsToggleFinder);
      await tester.tap(settingsToggleFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify advanced settings section opened
      expect(find.text('CONFIGURAR NOVO CONVITE'), findsOneWidget);
      expect(find.text('Expira em'), findsOneWidget);
      expect(find.text('Usos Máximos'), findsOneWidget);

      // Verify members list rendered
      expect(find.text('DevOwner'), findsOneWidget);
      expect(find.text('👑 Dono'), findsOneWidget);
    },
  );

  testWidgets(
    'InviteMemberDialog allows adding and removing members, and generating invites',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var memberCount = 1;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/members') && request.method == 'GET') {
          final list = [
            {
              'user_id': 'usr-1',
              'role': 'owner',
              'user': {'username': 'DevOwner', 'email': 'owner@nbx.com'},
            },
          ];
          if (memberCount > 1) {
            list.add({
              'user_id': 'usr-2',
              'role': 'member',
              'user': {'username': 'NewMember', 'email': 'new@nbx.com'},
            });
          }
          return http.Response(
            jsonEncode(list),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/members') && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['username'] == 'errorUser') {
            return http.Response(
              jsonEncode({'error': 'Usuário inválido'}),
              400,
              headers: {'content-type': 'application/json'},
            );
          }
          memberCount = 2;
          return http.Response(
            jsonEncode({'user_id': 'usr-2', 'role': 'member'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.contains('/members/usr-2') &&
            request.method == 'DELETE') {
          memberCount = 1;
          return http.Response('', 204);
        }

        if (request.url.path.endsWith('/invites') && request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/invites') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'code': 'newCodeXYZ',
              'server_id': 'srv-1',
              'max_age_seconds': 3600,
              'max_uses': 5,
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{}', 200);
      });

      final mockApiClient = ApiClient(client: mockClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(mockApiClient),
            authControllerProvider.overrideWith(
              (ref) =>
                  AuthNotifier(mockApiClient, restore: false)
                    ..state = const AuthState(
                      user: UserModel(
                        id: 'usr-1',
                        username: 'DevOwner',
                        email: 'owner@nbx.com',
                      ),
                      token: 'token',
                    ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InviteMemberDialog(server: testServer)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test empty input validation
      final addBtn = find.text('Adicionar');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.text('Digite o nome de usuário ou e-mail.'), findsOneWidget);

      // Test error from backend
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'errorUser');
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.text('Usuário inválido'), findsOneWidget);

      // Test successful add
      await tester.enterText(textField, 'NewMember');
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Membro adicionado com sucesso ao servidor!'),
        findsOneWidget,
      );
      expect(find.text('NewMember'), findsOneWidget);

      // Test remove member
      final removeBtn = find.byTooltip('Remover do Servidor');
      expect(removeBtn, findsOneWidget);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Test generate new invite code from settings
      final settingsToggle = find.text('Editar validade do link');
      await tester.tap(settingsToggle);
      await tester.pumpAndSettle();

      final generateBtn = find.text('Gerar Novo Código');
      await tester.ensureVisible(generateBtn);
      await tester.tap(generateBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('newCodeXYZ'), findsOneWidget);
    },
  );
}
