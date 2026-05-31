import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/main.dart';

void main() {
  testWidgets('App onboarding smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the Onboarding Screen is loaded by finding key text elements.
    expect(find.text('Elaaj'), findsOneWidget);
    expect(find.text('Find Nearby Pharmacies Easily'), findsOneWidget);
  });
}
