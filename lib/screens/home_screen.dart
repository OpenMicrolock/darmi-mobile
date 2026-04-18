import 'package:flutter/material.dart';

import '../api/lock_api.dart';
import '../settings/settings_store.dart';
import 'settings_screen.dart';

enum _Status { unknown, locked, unlocked }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, required this.settings});

  final SettingsStore store;
  final LockSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LockSettings _settings = widget.settings;
  late LockApi _api = _buildApi();

  _Status _state = _Status.unknown;
  bool _busy = false;
  String? _error;
  DateTime? _lastUpdated;

  LockApi _buildApi() => LockApi(
    host: _settings.host,
    port: _settings.port,
    token: _settings.token,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _run(Future<DeviceLockState> Function() op) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await op();
      setState(() {
        _state = s == DeviceLockState.locked ? _Status.locked : _Status.unlocked;
        _lastUpdated = DateTime.now();
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() => _error = 'Unauthorized — update your token');
      await _openSettings();
    } on LockApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() => _run(_api.status);
  Future<void> _lock() => _run(_api.lock);
  Future<void> _unlock() => _run(_api.unlock);

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<LockSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(store: widget.store, initial: _settings),
      ),
    );
    if (updated != null) {
      _api.dispose();
      setState(() {
        _settings = updated;
        _api = _buildApi();
        _state = _Status.unknown;
        _error = null;
      });
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Michael Lock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 24),
              _StatusCard(
                state: _state,
                busy: _busy,
                lastUpdated: _lastUpdated,
                host: _settings.host,
                port: _settings.port,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: _busy ? null : _unlock,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Unlock'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: _busy ? null : _lock,
                      icon: const Icon(Icons.lock),
                      label: const Text('Lock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.busy,
    required this.lastUpdated,
    required this.host,
    required this.port,
  });

  final _Status state;
  final bool busy;
  final DateTime? lastUpdated;
  final String host;
  final int port;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, color) = switch (state) {
      _Status.locked => (Icons.lock, 'LOCKED', scheme.primary),
      _Status.unlocked => (Icons.lock_open, 'UNLOCKED', scheme.tertiary),
      _Status.unknown => (Icons.help_outline, 'UNKNOWN', scheme.outline),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                key: ValueKey(state),
                size: 96,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$host:$port',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 16,
              child: busy
                  ? const LinearProgressIndicator()
                  : Text(
                      lastUpdated == null
                          ? 'Not fetched yet'
                          : 'Updated ${_formatTime(lastUpdated!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
  }
}
