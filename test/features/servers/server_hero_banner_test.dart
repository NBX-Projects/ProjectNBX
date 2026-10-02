import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:justtalking/features/servers/widgets/home_sections/server_hero_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testServer = ServerModel(
    id: 'srv-apex',
    name: 'Apex Predators',
    ownerId: 'usr-1',
    memberCount: 847,
    category: 'Gaming',
    isPublic: true,
    description: 'Servidor competitivo de Apex Legends',
    bannerUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e',
    iconUrl: 'https://images.unsplash.com/photo-custom-icon',
  );

  testWidgets(
    'ServerHeroBanner renders title, category, member count and Personalizar button',
    (tester) async {
      bool isCustomizing = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ServerHeroBanner(
                    server: testServer,
                    isMobile: false,
                    selectedBannerPreset: 0,
                    selectedAccentColor: const Color(0xFFF5CBA7),
                    isCustomizingBanner: isCustomizing,
                    onToggleCustomizeBanner: () {
                      setState(() => isCustomizing = !isCustomizing);
                    },
                    onSelectBannerPreset: (_) {},
                    onSelectAccentColor: (_) {},
                    onSaveCustomization: () async {},
                    memberCount: 847,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verifica que o nome e a contagem de membros aparecem
      expect(find.text('Apex Predators'), findsOneWidget);
      expect(find.text('Gaming · 847 membros'), findsOneWidget);
      expect(find.text('Personalizar'), findsOneWidget);

      // Clica no botão Personalizar
      await tester.tap(find.text('Personalizar'));
      await tester.pump();

      // Verifica que a gaveta de personalização abriu com as seções de Capa e Foto
      expect(find.text('Capa do Servidor (Banner)'), findsOneWidget);
      expect(find.text('Foto do Servidor (Ícone)'), findsOneWidget);
      expect(find.text('Salvar Capa'), findsOneWidget);
      expect(find.text('Salvar Foto'), findsOneWidget);
    },
  );
}
