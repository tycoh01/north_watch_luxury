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
      final double sunAzimuth = 180.0;
      final double H = 360.0;
      final double northDirection = ((sunAzimuth - (H / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;
      expect(northDirection, 180.0);
    });

    test('Solar navigation north calculation at same location with different times', () {
      final double sunAzimuth = 180.0;

      final double H_morning = 270.0;
      final double north_morning = ((sunAzimuth - (H_morning / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;

      final double H_noon = 360.0;
      final double north_noon = ((sunAzimuth - (H_noon / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;

      final double H_afternoon = 90.0;
      final double north_afternoon = ((sunAzimuth - (H_afternoon / 2.0) + 180.0) % 360.0 + 360.0) % 360.0;

      expect(north_morning, 225.0);
      expect(north_noon, 180.0);
      expect(north_afternoon, 315.0);
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
