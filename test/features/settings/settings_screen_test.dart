import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justtalking/core/localization/app_language.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/network/api_client.dart';
import 'package:justtalking/core/widgets/window_controls.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/auth/models/user_model.dart';
import 'package:justtalking/features/settings/screens/settings_screen.dart';
import 'package:justtalking/features/voice/controllers/audio_devices_controller.dart';
import 'package:justtalking/features/voice/services/audio_hardware_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioHardwareService extends AudioHardwareService {
  const MockAudioHardwareService();

  @override
  Future<List<AudioDeviceInfo>> getInputDevices() async => const [
        AudioDeviceInfo(
          deviceId: 'default',
          label: 'Microfone Teste',
          kind: 'audioinput',
        ),
      ];

  @override
  Future<List<AudioDeviceInfo>> getOutputDevices() async => const [
        AudioDeviceInfo(
          deviceId: 'default',
          label: 'Fone Teste',
          kind: 'audiooutput',
        ),
      ];

  @override
  Future<AudioSnapshot> getAudioDevicesSnapshot() async => (
        inputs: const [
          AudioDeviceInfo(
            deviceId: 'default',
            label: 'Microfone Teste',
            kind: 'audioinput',
          ),
        ],
        outputs: const [
          AudioDeviceInfo(
            deviceId: 'default',
            label: 'Fone Teste',
            kind: 'audiooutput',
          ),
        ],
        defaultInputId: 'default',
        defaultOutputId: 'default',
      );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsScreen renders sections and navigates tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testUser = UserModel(
      id: 'u100',
      username: 'GamerElite',
      email: 'elite@projectnbx.com',
      status: 'online',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthNotifier(ApiClient(), restore: false)
              ..state = const AuthState(
                user: testUser,
                token: 'dummy-token',
              ),
          ),
          audioHardwareServiceProvider.overrideWithValue(
            const MockAudioHardwareService(),
          ),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify desktop window controls and styled scrollbar are present
    expect(find.byType(WindowControls), findsOneWidget);
    expect(find.byType(Scrollbar), findsAtLeastNWidgets(1));

    // 1. Account section (default)
    expect(find.text('GamerElite'), findsAtLeastNWidgets(1));
    expect(find.text('elite@projectnbx.com'), findsAtLeastNWidgets(1));

    // 2. Navigate to Appearance & Language
    const strings = AppStrings(AppLanguage.pt);
    final appearanceFinder = find.text(strings.appearanceAndLanguage);
    expect(appearanceFinder, findsOneWidget);
    await tester.tap(appearanceFinder);
    await tester.pumpAndSettle();

    // Verify Appearance options
    expect(find.text(strings.themeSelector), findsOneWidget);

    // Switch theme
    final lightThemeOption = find.text('Claro');
    if (lightThemeOption.evaluate().isNotEmpty) {
      await tester.tap(lightThemeOption.first);
      await tester.pumpAndSettle();
    }

    // 3. Navigate to Voice & Video
    final voiceFinder = find.text(strings.voiceAndVideo);
    expect(voiceFinder, findsOneWidget);
    await tester.tap(voiceFinder);
    await tester.pumpAndSettle();

    // Verify Voice sliders & toggles
    expect(find.byType(Slider), findsAtLeastNWidgets(1));
    expect(find.byType(Switch), findsAtLeastNWidgets(1));

    // Toggle a switch
    final switchFinder = find.byType(Switch);
    if (switchFinder.evaluate().isNotEmpty) {
      await tester.tap(switchFinder.first);
      await tester.pumpAndSettle();
    }

    // 4. Navigate to Hotkeys & PTT
    final hotkeysFinder = find.text(strings.hotkeysAndPTT);
    expect(hotkeysFinder, findsOneWidget);
    await tester.tap(hotkeysFinder);
    await tester.pumpAndSettle();

    // 5. Navigate to System Status
    final systemFinder = find.text(strings.systemStatusTitle);
    expect(systemFinder, findsOneWidget);
    await tester.tap(systemFinder);
    await tester.pumpAndSettle();

    // 6. Close button
    final closeFinder = find.byIcon(LucideIcons.x);
    if (closeFinder.evaluate().isNotEmpty) {
      await tester.tap(closeFinder.first);
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'SettingsScreen mobile layout renders master menu and navigates into detail view',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testUser = UserModel(
        id: 'u200',
        username: 'MobileGamer',
        email: 'mobile@projectnbx.com',
        status: 'online',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => AuthNotifier(ApiClient(), restore: false)
                ..state = const AuthState(
                  user: testUser,
                  token: 'dummy-token',
                ),
            ),
            audioHardwareServiceProvider.overrideWithValue(
              const MockAudioHardwareService(),
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      const strings = AppStrings(AppLanguage.pt);

      // 1. Mobile Master view: should NOT show desktop WindowControls
      expect(find.byType(WindowControls), findsNothing);

      // Verify header title
      expect(find.text(strings.settingsTitle), findsOneWidget);

      // In master menu, sections are listed with chevron indicators
      expect(find.text(strings.myAccount), findsOneWidget);
      expect(find.text(strings.appearanceAndLanguage), findsOneWidget);
      expect(find.text(strings.voiceAndVideo), findsOneWidget);
      expect(find.text(strings.hotkeysAndPTT), findsOneWidget);
      expect(find.text(strings.systemStatusTitle), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsAtLeastNWidgets(5));

      // Detail content (e.g. user email) should not be rendered yet in the master list
      expect(find.text('mobile@projectnbx.com'), findsNothing);

      // 2. Drill-down into "Minha Conta"
      await tester.tap(find.text(strings.myAccount));
      await tester.pumpAndSettle();

      // Now in Detail view:
      // Detail header has a back button (arrowLeft)
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

      // Profile details are rendered
      expect(find.text('MobileGamer'), findsAtLeastNWidgets(1));
      expect(find.text('mobile@projectnbx.com'), findsAtLeastNWidgets(1));
      expect(find.text('Editar Perfil'), findsOneWidget);

      // 3. Tap back button to return to master menu
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      // Back in master menu
      expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
      expect(find.text(strings.myAccount), findsOneWidget);
      expect(find.text('mobile@projectnbx.com'), findsNothing);

      // 4. Drill-down into "Status dos Serviços & Conexão"
      await tester.tap(find.text(strings.systemStatusTitle));
      await tester.pumpAndSettle();

      // Verify system status detail view
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.text('INFRAESTRUTURA DE SERVIÇOS'), findsOneWidget);
      expect(find.text('Banco de Dados & Storage'), findsOneWidget);

      // Return back
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
    },
  );

  testWidgets(
    'SettingsScreen on Android/iOS hides hotkeys section and falls back to voice',
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
                    id: 'u300',
                    username: 'PhoneUser',
                    email: 'phone@projectnbx.com',
                  ),
                  token: 'token',
                ),
            ),
            audioHardwareServiceProvider.overrideWithValue(
              const MockAudioHardwareService(),
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(
              supportsHotkeys: false,
              initialSection: 'hotkeys',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      const strings = AppStrings(AppLanguage.pt);

      // Hotkeys section must NOT exist
      expect(find.text(strings.hotkeysAndPTT), findsNothing);

      // Because initialSection was 'hotkeys' but supportsHotkeys is false,
      // it should fall back to voice section
      expect(find.text(strings.voiceAndVideo), findsAtLeastNWidgets(1));

      // Pop back to master menu
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      // In master menu, hotkeys item is NOT present
      expect(find.text(strings.hotkeysAndPTT), findsNothing);
      expect(find.text(strings.myAccount), findsOneWidget);
      expect(find.text(strings.voiceAndVideo), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsScreen renders hotkeys section responsively on mobile screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
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
                    id: 'u400',
                    username: 'Tester',
                    email: 'tester@projectnbx.com',
                  ),
                  token: 'token',
                ),
            ),
            audioHardwareServiceProvider.overrideWithValue(
              const MockAudioHardwareService(),
            ),
          ],
          child: const MaterialApp(
            home: SettingsScreen(
              supportsHotkeys: true,
              initialSection: 'hotkeys',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      const strings = AppStrings(AppLanguage.pt);

      // Detail header displays hotkeys title
      expect(find.text(strings.hotkeysAndPTT), findsAtLeastNWidgets(1));

      // Reset button is displayed in full width on mobile
      expect(find.text('Restaurar Padrões'), findsOneWidget);

      // Voice activity and PTT cards are displayed stacked
      expect(find.text(strings.voiceActivity), findsOneWidget);
      expect(find.text(strings.pushToTalk), findsOneWidget);

      // Categorized shortcuts exist and don't overflow
      expect(find.text('ÁUDIO & TRANSMISSÃO'), findsOneWidget);
      expect(find.text('Mutar / Desmutar Microfone'), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsAtLeastNWidgets(1));
    },
  );
}
