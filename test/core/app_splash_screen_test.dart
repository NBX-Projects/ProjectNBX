import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justtalking/core/widgets/app_splash_screen.dart';

void main() {
  testWidgets('AppSplashScreen renders branding and progresses boot sequence', (
    WidgetTester tester,
  ) async {
    bool completed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AppSplashScreen(
            onComplete: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    // Initial render shows branding and app name
    expect(find.text('Just Talking'), findsOneWidget);
    expect(find.text('NBX Projects • Voz e colaboração em tempo real'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(completed, isFalse);

    // Pump enough time for the entire boot sequence to finish
    await tester.pump(const Duration(seconds: 4));

    // After sequence completes, onComplete callback is fired
    expect(completed, isTrue);
  });
}
