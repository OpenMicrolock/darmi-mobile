import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:michael_lock/main.dart';

void main() {
  testWidgets('App renders first-run screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MichaelLockApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Michael Lock'), findsWidgets);
    expect(find.byIcon(Icons.lock), findsWidgets);
  });
}
