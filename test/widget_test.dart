import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clock_app/main.dart';

void main() {
  testWidgets('Offline clock app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: OfflineWidget(),
    ));

    expect(find.text('Offline Clock App'), findsOneWidget);
  });
}
