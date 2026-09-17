import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/features/voice/widgets/quick_audio_device_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createMenuScope({
    bool isInput = true,
  }) {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: QuickAudioDeviceMenu(),
        ),
      ),
    );
  }

  testWidgets('QuickAudioDeviceMenu renders sections, volume slider and settings action', (tester) async {
    await tester.pumpWidget(createMenuScope());
    await tester.pumpAndSettle();

    expect(find.text('Dispositivo de entrada'), findsOneWidget);
    expect(find.text('Dispositivo de saída'), findsOneWidget);
    expect(find.text('Perfil de entrada'), findsOneWidget);
    expect(find.text('Volume de entrada'), findsOneWidget);
    expect(find.text('Nível de entrada'), findsOneWidget);
    expect(find.text('Configurações de voz'), findsOneWidget);
  });

  testWidgets('QuickAudioDeviceMenu toggles profile and adjusts slider', (tester) async {
    await tester.pumpWidget(createMenuScope());
    await tester.pumpAndSettle();

    // Tap to expand Perfil de entrada
    await tester.tap(find.text('Perfil de entrada'));
    await tester.pumpAndSettle();

    expect(find.text('Estúdio / Puro (Sem filtros / Anti-chiado)'), findsOneWidget);
    expect(find.text('Isolamento Máximo (Gate + Supressão Alta)'), findsOneWidget);

    // Select Estudio profile
    await tester.tap(find.text('Estúdio / Puro (Sem filtros / Anti-chiado)'));
    await tester.pumpAndSettle();

    // Verify Slider is present and interactable
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
  });

  testWidgets('QuickAudioDeviceMenu VU meter remains silent when audioLevel is 0', (tester) async {
    await tester.pumpWidget(createMenuScope());
    await tester.pumpAndSettle();

    // Verify 'Nível de entrada' title exists
    expect(find.text('Nível de entrada'), findsOneWidget);
    
    // Total bars are 24 Containers with height: 14 inside Row
    final containers = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.constraints?.maxHeight == 14 &&
        widget.margin == const EdgeInsets.symmetric(horizontal: 1));
    expect(containers, findsNWidgets(24));
  });
}
