import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'settings/settings_store.dart';

void main() {
  runApp(const MicrolockApp());
}

class MicrolockApp extends StatelessWidget {
  const MicrolockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microlock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _Bootstrap(),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final _store = SettingsStore();
  late Future<LockSettings?> _future;

  @override
  void initState() {
    super.initState();
    _future = _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LockSettings?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final settings = snapshot.data;
        if (settings == null || !settings.isComplete) {
          return _FirstRun(store: _store);
        }
        return HomeScreen(store: _store, settings: settings);
      },
    );
  }
}

class _FirstRun extends StatelessWidget {
  const _FirstRun({required this.store});

  final SettingsStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 80),
                const SizedBox(height: 16),
                Text(
                  'Microlock',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your device to get started.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Open settings'),
                  onPressed: () async {
                    final saved = await Navigator.of(context)
                        .push<LockSettings>(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(store: store),
                          ),
                        );
                    if (saved != null && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              HomeScreen(store: store, settings: saved),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
