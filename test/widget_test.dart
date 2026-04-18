import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:microlock/main.dart';

void main() {
  testWidgets('App renders first-run screen', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const MicrolockApp());
    await tester.pump();

    expect(find.text('Microlock'), findsWidgets);
    expect(find.byIcon(Icons.lock), findsWidgets);
  });
}
