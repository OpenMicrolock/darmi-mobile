import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'settings/settings_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MicrolockApp());
}

class MicrolockApp extends StatelessWidget {
  const MicrolockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SettingsStore();

    return MaterialApp(
      title: 'Microlock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: SplashScreen(store: store),
    );
  }
}
