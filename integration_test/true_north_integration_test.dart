import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clock_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('True North & HIL Simulation Integration Tests', () {
    testWidgets('Verify True North heading with mock compass provider', (WidgetTester tester) async {
      double mockHeading = 120.0;
      await tester.pumpWidget(MaterialApp(
        home: app.OfflineWidget(
          compassProvider: () => mockHeading,
        ),
      ));

      // Navigate to State 3: Compass North
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();

      expect(find.textContaining('120.0°'), findsOneWidget);

      // Verify state switching to North Compare
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(-100, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4. North Compare'));
      await tester.pumpAndSettle();
      expect(find.text('Watch Dial Method: North Compare'), findsOneWidget);
    });

    testWidgets('Verify Calibration State 5 UI and interaction flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Scroll horizontal bar to reveal State 5
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5. Calibrate'));
      await tester.pumpAndSettle();

      expect(find.text('State 5: Stabilized Compass Calibration'), findsOneWidget);
      expect(find.text('Calibration Idle'), findsOneWidget);

      // Start calibration
      await tester.tap(find.text('Start Calibration'));
      await tester.pumpAndSettle();
      expect(find.text('Calibration Active (Rotate phone in figure-8)...'), findsOneWidget);

      // Stop calibration
      await tester.tap(find.text('Stop Calibration'));
      await tester.pumpAndSettle();
      expect(find.text('Calibration Idle'), findsOneWidget);
    });
  });
}
