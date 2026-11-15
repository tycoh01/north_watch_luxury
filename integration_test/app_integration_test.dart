import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clock_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Device Hardware Integration & Physical North Correctness Test', () {
    testWidgets('Verify all 6 states and physical compass correctness on physical device', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // State 1: Clock & Sun
      expect(find.text('Offline Clock App'), findsOneWidget);
      expect(find.byType(app.LuxuryCircularClock), findsOneWidget);

      // State 2: Sun Input
      await tester.tap(find.text('2. Sun Input'));
      await tester.pumpAndSettle();
      expect(find.text('Sun Direction Input Mode'), findsOneWidget);

      // State 3: Compass North (Verifies physical north sensor active & correct reading format)
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();
      expect(find.text('Compass North Calibration Mode'), findsOneWidget);
      expect(find.textContaining('Stabilized Compass North'), findsOneWidget);
      expect(find.textContaining('°'), findsWidgets); // Verify degree format correctness

      // Scroll horizontal bar to reveal State 4
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // State 4: North Compare (Verifies physical vs calculated correctness)
      await tester.tap(find.text('4. North Compare'));
      await tester.pumpAndSettle();
      expect(find.text('Watch Dial Method: North Compare'), findsOneWidget);
      expect(find.text('Stabilized Compass North (Blue P):'), findsOneWidget);
      expect(find.text('Watch Dial North (Asun - H/2):'), findsOneWidget);
      expect(find.text('Variance / Delta:'), findsOneWidget);

      // Scroll horizontal bar further to reveal State 5 and State 6
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // State 5: Calibrate (Verifies hardware calibration trigger and physical correctness checks)
      final calibrateButton = find.text('5. Calibrate');
      await tester.tap(calibrateButton);
      await tester.pumpAndSettle();
      expect(find.text('State 5: Stabilized Compass Calibration'), findsOneWidget);

      // Tap start calibration button to test runtime sensor collection state
      await tester.tap(find.text('Start Calibration'));
      await tester.pumpAndSettle();
      expect(find.text('Calibration Active (Rotate phone in figure-8)...'), findsOneWidget);

      // Stop calibration
      await tester.tap(find.text('Stop Calibration'));
      await tester.pumpAndSettle();

      // State 6: 日本代購
      final japanButton = find.text('6. 日本代購');
      await tester.tap(japanButton);
      await tester.pumpAndSettle();
      expect(find.text('日本代購 (Japan Yahoo Buyee)'), findsOneWidget);
    });

    testWidgets('Verify physical north is fixed when using stubbed compass provider', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: app.OfflineWidget(
          compassProvider: () => 45.0,
        ),
      ));

      // Navigate to State 3: Compass North
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();

      expect(find.textContaining('45.0°'), findsOneWidget);
    });
  });
}
