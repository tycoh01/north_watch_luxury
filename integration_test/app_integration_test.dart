import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clock_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Clock App Integration Test', () {
    testWidgets('Navigate through all 4 states including North Comparison', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // State 1: Clock & Sun
      expect(find.text('Offline Clock App'), findsOneWidget);
      expect(find.text('Sun Intensity: 5'), findsOneWidget);

      // Tap State 2: Sun Input
      await tester.tap(find.text('2. Sun Input'));
      await tester.pumpAndSettle();
      expect(find.text('Sun Direction Input Mode'), findsOneWidget);

      // Tap State 3: Compass North
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();
      expect(find.text('Compass North Calibration Mode'), findsOneWidget);

      // Tap State 4: North Compare
      await tester.tap(find.text('4. North Compare'));
      await tester.pumpAndSettle();
      expect(find.text('Physical vs. Calculated North Comparison'), findsOneWidget);
      expect(find.text('Physical Compass North:'), findsOneWidget);
      expect(find.text('Calculated Solar North:'), findsOneWidget);
      expect(find.text('Variance / Delta:'), findsOneWidget);
    });
  });
}
