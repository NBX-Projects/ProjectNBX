import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projectnbx/features/auth/screens/login_screen.dart';
import 'package:projectnbx/main.dart';

void main() {
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
}
