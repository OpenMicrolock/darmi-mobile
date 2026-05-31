import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: scheme.primary),
                    title: const Text('Microlock'),
                    subtitle: const Text('Version 1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: scheme.primary),
                    title: const Text('Smart Lock'),
                    subtitle: const Text('ESP32-based lock controller'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lightbulb_outline, color: scheme.primary),
                    title: const Text('Smart Lamp'),
                    subtitle: const Text('ESP32-based lamp controller'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              child: ListTile(
                leading: Icon(Icons.code, color: scheme.primary),
                title: const Text('PlatformIO + Arduino + Flutter'),
                subtitle: const Text('Open source IoT stack'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
