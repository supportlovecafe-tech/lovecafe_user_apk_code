import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_eats_customer/customer_app.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CinemaEatsCustomerApp(),
      ),
    );

    // Verify that the app is constructed successfully
    expect(find.byType(CinemaEatsCustomerApp), findsOneWidget);
  });
}
