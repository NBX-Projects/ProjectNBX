import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/main.dart';

void main() {
  testWidgets('App smoke test and launch test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ProjectNBXApp(),
      ),
    );
    expect(find.byType(ProjectNBXApp), findsOneWidget);
  });
}
