import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/localization/app_language.dart';
import 'package:projectnbx/core/localization/app_strings.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/settings/screens/settings_screen.dart';
import 'package:projectnbx/features/voice/controllers/audio_devices_controller.dart';
import 'package:projectnbx/features/voice/services/audio_hardware_service.dart';
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
}
