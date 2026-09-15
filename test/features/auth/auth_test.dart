import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/theme/app_theme.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeApiClient extends ApiClient {
  bool shouldFail = false;
  String failureMessage = 'Erro de autenticação';

  @override
  Future<AuthResponse> login(String email, String password) async {
    if (shouldFail) throw Exception(failureMessage);
    return const AuthResponse(
      token: 'jwt-test-token',
      user: UserModel(
        id: 'u-1',
        username: 'TestUser',
        email: 'test@nbx.com',
        status: 'online',
        avatarUrl: 'https://example.com/avatar.png',
      ),
    );
  }

  @override
  Future<AuthResponse> register(
    String username,
    String email,
    String password,
  ) async {
    if (shouldFail) throw Exception(failureMessage);
    return AuthResponse(
      token: 'jwt-test-token-reg',
      user: UserModel(
        id: 'u-2',
        username: username,
        email: email,
        status: 'online',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          methodCall,
        ) async {
          if (methodCall.method == 'isMaximized') return false;
          return null;
        });
  });

  group('UserModel & AuthResponse', () {
    test('UserModel fromJson / toJson', () {
      final json = {
        'id': 'usr-123',
        'username': 'gamer_dev',
        'email': 'dev@nbx.io',
        'status': 'idle',
        'avatar_url': 'https://nbx.io/pic.jpg',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'usr-123');
      expect(user.username, 'gamer_dev');
      expect(user.email, 'dev@nbx.io');
      expect(user.status, 'idle');
      expect(user.avatarUrl, 'https://nbx.io/pic.jpg');

      final serialized = user.toJson();
      expect(serialized['id'], 'usr-123');
      expect(serialized['username'], 'gamer_dev');
      expect(serialized['email'], 'dev@nbx.io');
      expect(serialized['status'], 'idle');
      expect(serialized['avatar_url'], 'https://nbx.io/pic.jpg');
    });

    test('UserModel defaults when JSON has missing fields', () {
      final user = UserModel.fromJson({});
      expect(user.id, '');
      expect(user.username, '');
      expect(user.email, '');
      expect(user.status, 'online');
      expect(user.avatarUrl, isNull);
    });

    test('AuthResponse fromJson', () {
      final res = AuthResponse.fromJson({
        'token': 'tok-abc',
        'user': {
          'id': '1',
          'username': 'Alice',
          'email': 'alice@test.com',
          'status': 'dnd',
        },
      });

      expect(res.token, 'tok-abc');
      expect(res.user.id, '1');
      expect(res.user.username, 'Alice');
      expect(res.user.status, 'dnd');
    });
  });

  group('AuthState & AuthNotifier', () {
    test('AuthState properties and copyWith', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);

      final withUser = state.copyWith(
        user: const UserModel(id: '1', username: 'Bob', email: 'b@b.com'),
        token: 'tok-123',
        isLoading: true,
        errorMessage: 'Err',
      );
      expect(withUser.isAuthenticated, isTrue);
      expect(withUser.isLoading, isTrue);
      expect(withUser.errorMessage, 'Err');

      final cleared = withUser.copyWith(clearError: true, isLoading: false);
      expect(cleared.errorMessage, isNull);
      expect(cleared.isLoading, isFalse);
    });

    test('AuthNotifier restoreSession from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'saved-jwt',
        'auth_user': jsonEncode({
          'id': 'saved-id',
          'username': 'SavedUser',
          'email': 'saved@nbx.com',
          'status': 'online',
        }),
      });

      final fakeApi = FakeApiClient();
      final notifier = AuthNotifier(fakeApi, restore: true);

      // Aguarda leitura assíncrona
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.token, 'saved-jwt');
      expect(notifier.state.user?.username, 'SavedUser');
      expect(fakeApi.authToken, 'saved-jwt');
    });

    test('AuthNotifier login success and failure', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeApi = FakeApiClient();
      final notifier = AuthNotifier(fakeApi, restore: false);

      // Login Sucesso
      final success = await notifier.login('test@nbx.com', 'Pass123!');
      expect(success, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, 'TestUser');
      expect(notifier.state.errorMessage, isNull);

      // Login Falha
      fakeApi.shouldFail = true;
      fakeApi.failureMessage = 'Credenciais inválidas';
      final failResult = await notifier.login('test@nbx.com', 'Wrong');
      expect(failResult, isFalse);
      expect(notifier.state.errorMessage, 'Credenciais inválidas');

      notifier.clearError();
      expect(notifier.state.errorMessage, isNull);
    });

    test('AuthNotifier register success and failure', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeApi = FakeApiClient();
      final notifier = AuthNotifier(fakeApi, restore: false);

      // Register Sucesso
      final success = await notifier.register(
        'NovoUser',
        'novo@nbx.com',
        'Pass123!',
      );
      expect(success, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.username, 'NovoUser');

      // Register Falha
      fakeApi.shouldFail = true;
      fakeApi.failureMessage = 'Email já cadastrado';
      final fail = await notifier.register(
        'NovoUser',
        'novo@nbx.com',
        'Pass123!',
      );
      expect(fail, isFalse);
      expect(notifier.state.errorMessage, 'Email já cadastrado');
    });

    test('AuthNotifier logout clears state and SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'tok',
        'auth_user': jsonEncode({'id': 'u1', 'username': 'U1', 'email': 'e'}),
      });

      final fakeApi = FakeApiClient();
      final notifier = AuthNotifier(fakeApi, restore: false);
      await notifier.logout();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.user, isNull);
      expect(notifier.state.token, isNull);
      expect(fakeApi.authToken, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders LoginScreen and interacts with UI elements', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final fakeApi = FakeApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApi),
            authControllerProvider.overrideWith(
              (ref) => AuthNotifier(fakeApi, restore: false),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica branding e campos
      expect(find.text('ProjectNBX'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email, Senha
      expect(find.text('ACESSAR'), findsOneWidget);

      // Preenche credenciais de demonstração clicando no botão Demo
      final demoBtn = find.textContaining('Preencher credenciais');
      expect(demoBtn, findsOneWidget);
      await tester.tap(demoBtn);
      await tester.pumpAndSettle();

      // Alterna visibilidade da senha
      final obscureBtn = find.byType(IconButton).last;
      await tester.tap(obscureBtn);
      await tester.pumpAndSettle();

      // Alterna modo para Cadastro
      final registerTab = find.text('Criar Conta');
      expect(registerTab, findsOneWidget);
      await tester.tap(registerTab);
      await tester.pumpAndSettle();

      // Agora deve ter 3 campos (Usuário, Email, Senha)
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('CRIAR CONTA'), findsOneWidget);

      // Alterna de volta para Login
      final loginTab = find.text('Entrar');
      expect(loginTab, findsOneWidget);
      await tester.tap(loginTab);
      await tester.pumpAndSettle();

      // Clica no botão de alternar tema
      final themeToggle = find.textContaining('Tema');
      expect(themeToggle, findsOneWidget);
      await tester.tap(themeToggle);
      await tester.pumpAndSettle();

      // Clica no botão de acessar
      final submitBtn = find.widgetWithText(ElevatedButton, 'ACESSAR');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('Opens and interacts with Server Config Dialog', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final fakeApi = FakeApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApi),
            authControllerProvider.overrideWith(
              (ref) => AuthNotifier(fakeApi, restore: false),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clica no botão de IP do Servidor
      final hostChip = find.text('localhost:8080');
      expect(hostChip, findsOneWidget);
      await tester.tap(hostChip);
      await tester.pumpAndSettle();

      // Verifica se o diálogo abriu
      expect(find.text('Endereço do Backend (Host)'), findsOneWidget);

      // Clica no botão de fechar diálogo
      final closeBtn = find.byIcon(LucideIcons.x).last;
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Diálogo fechou
      expect(find.text('Endereço do Backend (Host)'), findsNothing);
    });
  });
}
