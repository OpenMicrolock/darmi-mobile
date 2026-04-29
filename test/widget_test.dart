import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:microlock/main.dart';

void main() {
  testWidgets('App renders first-run screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MichaelLockApp());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Welcome to Microlock'), findsOneWidget);
    expect(find.text('Set Up New Device'), findsOneWidget);
  });
}
