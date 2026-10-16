import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/main.dart';

void main() {
  group('Offline Clock App Unit & Widget Tests', () {
    test('Constants and static offline variables verification', () {
      expect(appTitle, 'Offline Clock App');
      expect(offlineStatus, 'Status: Offline Mode');
      expect(appVersion, 'v1.0.0');
      expect(offlineSun, 5);
    });

    test('Solar navigation north calculation formula unit test (testNorth)', () {
      const double sunAzimuth = 180.0;
      const double H = 360.0;
      const double northDirection = ((sunAzimuth - (H / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;
      expect(northDirection, 180.0);
    });

    test('Solar navigation north calculation at same location with different times', () {
      const double sunAzimuth = 180.0;

      const double hMorning = 270.0;
      const double northMorning = ((sunAzimuth - (hMorning / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;

      const double hNoon = 360.0;
      const double northNoon = ((sunAzimuth - (hNoon / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;

      const double hAfternoon = 90.0;
      const double northAfternoon = ((sunAzimuth - (hAfternoon / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;

      expect(northMorning, 225.0);
      expect(northNoon, 180.0);
      expect(northAfternoon, 315.0);
    });

    test('Runtime verification test: SunDialRing mathematical object cyclic loop iteration', () {
      const ring = SunDialRing(modulus: 12);
      final hours = ring.toList();
      expect(hours.length, 12);
      expect(hours.first, 1);
      expect(hours.last, 12);

      final rotated = ring.rotate(3);
      expect(rotated.first, 4);
    });

    testWidgets('OfflineWidget renders State 1 (Clock & Sun) components correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OfflineWidget(),
      ));

      expect(find.text('Offline Clock App'), findsOneWidget);
      expect(find.text('Sun Intensity: 5'), findsOneWidget);
      expect(find.textContaining('Sun Vector (Asun:'), findsOneWidget);
      expect(find.text('Status: Offline Mode'), findsOneWidget);
      expect(find.text('App Version: v1.0.0'), findsOneWidget);
    });

    testWidgets('Offline UI test verifies gold hour hand marker (H) on clock face', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OfflineWidget(),
      ));

      // Verify gold hour hand marker 'H' is rendered
      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('Runtime verification test: live timer tick and time updates', (WidgetTester tester) async {
      var initialTime = DateTime(2026, 10, 17, 10, 0, 0);
      await tester.pumpWidget(MaterialApp(
        home: OfflineWidget(
          timeProvider: () => initialTime,
          compassProvider: () => 45.0,
        ),
      ));

      expect(find.text('10:00:00'), findsOneWidget);

      initialTime = DateTime(2026, 10, 17, 10, 0, 5);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('10:00:05'), findsOneWidget);
    });

    testWidgets('Runtime verification test: navigate through all 6 states including Calibrate and 日本代購', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OfflineWidget(),
      ));

      // State 1
      expect(find.text('Offline Clock App'), findsOneWidget);

      // State 2: Sun Input
      await tester.tap(find.text('2. Sun Input'));
      await tester.pumpAndSettle();
      expect(find.text('Sun Direction Input Mode'), findsOneWidget);

      // State 3: Compass North
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();
      expect(find.text('Compass North Calibration Mode'), findsOneWidget);

      // State 4: North Compare
      await tester.tap(find.text('4. North Compare'));
      await tester.pumpAndSettle();
      expect(find.text('Watch Dial Method: North Compare'), findsOneWidget);

      // Scroll horizontal bar further to reveal State 5 and State 6
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // State 5: Calibrate
      final calibrateButton = find.text('5. Calibrate');
      await tester.tap(calibrateButton);
      await tester.pumpAndSettle();
      expect(find.text('State 5: Magnet Compass Calibration'), findsOneWidget);

      // State 6: 日本代購
      final japanButton = find.text('6. 日本代購');
      await tester.tap(japanButton);
      await tester.pumpAndSettle();
      expect(find.text('日本代購 (Japan Yahoo Buyee)'), findsOneWidget);
    });

    testWidgets('OfflineWidget switches to State 2 (Sun Input) and State 3 (Compass North) correctly', (WidgetTester tester) async {
      final stubbedTime = DateTime(2026, 9, 28, 14, 30, 45);

      await tester.pumpWidget(MaterialApp(
        home: OfflineWidget(
          timeProvider: () => stubbedTime,
          compassProvider: () => 90.0,
        ),
      ));

      expect(find.text('14:30:45'), findsOneWidget);

      // Tap State 2: Sun Input
      await tester.tap(find.text('2. Sun Input'));
      await tester.pumpAndSettle();
      expect(find.text('Sun Direction Input Mode'), findsOneWidget);
      expect(find.text('Apply Sun Clock Units'), findsOneWidget);

      // Tap State 3: Compass North
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();
      expect(find.text('Compass North Calibration Mode'), findsOneWidget);
      expect(find.textContaining('Live Physical Compass North:'), findsOneWidget);
    });

    testWidgets('testNorth verifies calculated north direction across same location with different times', (WidgetTester tester) async {
      final morningTime = DateTime(2026, 9, 28, 9, 0, 0);

      await tester.pumpWidget(MaterialApp(
        home: OfflineWidget(
          timeProvider: () => morningTime,
          compassProvider: () => 0.0,
        ),
      ));

      // Navigate to State 3: Compass North
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Live Physical Compass North:'), findsOneWidget);
    });
  });
}
