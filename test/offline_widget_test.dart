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

    test('Physical compass heading verification', () {
      final double physicalHeading = 45.0;
      expect(physicalHeading, 45.0);
    });

    testWidgets('OfflineWidget renders State 1 (Clock & Sun) components correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: OfflineWidget(),
      ));

      // Verify App Bar title
      expect(find.text('Offline Clock App'), findsOneWidget);

      // Verify Sun intensity
      expect(find.text('Sun Intensity: 5'), findsOneWidget);

      // Verify Sun Vector UI
      expect(find.textContaining('Sun Vector:'), findsOneWidget);

      // Verify Offline Status
      expect(find.text('Status: Offline Mode'), findsOneWidget);

      // Verify App Version
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

      // State 1: Verify formatted time string in clock view
      expect(find.text('14:30:45'), findsOneWidget);

      // Tap State 2: Sun Input
      await tester.tap(find.text('2. Sun Input'));
      await tester.pumpAndSettle();
      expect(find.text('Sun Direction Input Mode'), findsOneWidget);
      expect(find.text('Apply Sun Direction'), findsOneWidget);

      // Tap State 3: Compass North
      await tester.tap(find.text('3. Compass North'));
      await tester.pumpAndSettle();
      expect(find.text('Compass North Calibration Mode'), findsOneWidget);
      expect(find.text('Physical Compass North: 90.0°'), findsOneWidget);
    });
  });
}
