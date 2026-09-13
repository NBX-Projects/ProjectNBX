import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/main.dart';

void main() {
  testWidgets('App smoke test and launch test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: ProjectNBXApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(ProjectNBXApp), findsOneWidget);
  });
}
