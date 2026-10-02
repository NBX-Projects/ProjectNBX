import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justtalking/core/updater/update_controller.dart';
import 'package:justtalking/core/updater/update_models.dart';
import 'package:justtalking/core/updater/update_service.dart';
import 'package:justtalking/core/updater/widgets/top_bar_update_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeUpdateService extends UpdateService {
  _FakeUpdateService() : super();
}

void main() {
  group('TopBarUpdateButton Widget Tests', () {
    testWidgets('Renders nothing when no update is available', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TopBarUpdateButton(isDark: true),
            ),
          ),
        ),
      );

      expect(find.byType(TopBarUpdateButton), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowDownToLine), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Renders download arrow when update is available', (tester) async {
      final container = ProviderContainer(
        overrides: [
          updateServiceProvider.overrideWithValue(_FakeUpdateService()),
        ],
      );

      final controller = container.read(updateControllerProvider.notifier);
      controller.state = const UpdateState(
        status: UpdateStatus.available,
        currentVersion: '1.0.8',
        latestRelease: ReleaseInfo(
          tagName: 'v1.0.9',
          version: '1.0.9',
          name: 'v1.0.9',
          body: '',
          htmlUrl: '',
          assets: [],
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TopBarUpdateButton(isDark: true),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(LucideIcons.arrowDownToLine), findsOneWidget);
    });

    testWidgets('Renders progress indicator when downloading', (tester) async {
      final container = ProviderContainer(
        overrides: [
          updateServiceProvider.overrideWithValue(_FakeUpdateService()),
        ],
      );

      final controller = container.read(updateControllerProvider.notifier);
      controller.state = const UpdateState(
        status: UpdateStatus.downloading,
        currentVersion: '1.0.8',
        downloadProgress: 0.65,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TopBarUpdateButton(isDark: true),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('65'), findsOneWidget);
    });

    testWidgets('Renders refresh/ready icon when ready to install', (tester) async {
      final container = ProviderContainer(
        overrides: [
          updateServiceProvider.overrideWithValue(_FakeUpdateService()),
        ],
      );

      final controller = container.read(updateControllerProvider.notifier);
      controller.state = const UpdateState(
        status: UpdateStatus.readyToInstall,
        currentVersion: '1.0.8',
        downloadedFilePath: 'C:\\fake\\installer.exe',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TopBarUpdateButton(isDark: true),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(LucideIcons.refreshCw), findsOneWidget);
    });
  });
}
