import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:microlock/main.dart';
import 'package:microlock/screens/splash_screen.dart';
import 'package:microlock/screens/onboarding_screen.dart';

void main() {
  testWidgets('App flows from Splash to Onboarding screen when no devices registered', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const MicrolockApp());
    
    // Verify we are initially on the SplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the minimum splash duration of 1.5 seconds to elapse
    await tester.pump(const Duration(milliseconds: 1500));
    // Let the navigation transition settle
    await tester.pumpAndSettle();

    // Verify we transitioned to the OnboardingScreen
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Your Smart Home,\nOne Tap Away'), findsOneWidget);
    expect(find.text('Smart Lock Control'), findsOneWidget);
    expect(find.text('Smart Lamp Control'), findsOneWidget);
    expect(find.text('Add First Device'), findsOneWidget);
  });
}
