import 'package:flutter/material.dart';

import '../api/lock_api.dart';
import '../branding.dart';
import '../settings/settings_store.dart';
import '../widgets/microlock_logo.dart';
import 'provisioning_screen.dart';

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
  bool _showLastError = false;
  String? _lastError;
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
      _showLastError = false;
      _lastError = null;
    });
    try {
      final s = await op();
      setState(() {
        _state = s == DeviceLockState.locked ? _Status.locked : _Status.unlocked;
        _lastUpdated = DateTime.now();
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _lastError = 'Invalid token — please check your settings';
        _showLastError = true;
      });
    } on LockApiException catch (e) {
      setState(() {
        _lastError = e.message;
        _showLastError = true;
      });
    } catch (e) {
      setState(() {
        _lastError = 'Connection failed';
        _showLastError = true;
      });
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
        builder: (_) => ProvisioningScreen(
          store: widget.store,
          initial: _settings,
        ),
      ),
    );

    if (updated == null) return;

    _api.dispose();
    setState(() {
      _settings = updated;
      _api = _buildApi();
      _state = _Status.unknown;
      _showLastError = false;
      _lastError = null;
    });
    _refresh();
  }

  Future<void> _openProvisioning() async {
    final updated = await Navigator.of(context).push<LockSettings>(
      MaterialPageRoute(
        builder: (_) => ProvisioningScreen(
          store: widget.store,
          initial: _settings,
        ),
      ),
    );

    if (updated == null) return;

    _api.dispose();
    setState(() {
      _settings = updated;
      _api = _buildApi();
      _state = _Status.unknown;
      _showLastError = false;
      _lastError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Status card
              _StatusCard(
                state: _state,
                busy: _busy,
                lastUpdated: _lastUpdated,
                host: _settings.host,
                port: _settings.port,
              ),
              const SizedBox(height: 20),
              // Error banner
              if (_lastError != null && _showLastError) ...[
                Semantics(
                  label: 'Error: $_lastError',
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: scheme.onErrorContainer,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _lastError!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Action buttons — large touch targets
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.lock_rounded,
                      label: 'Lock',
                      color: scheme.primary,
                      onColor: scheme.onPrimary,
                      onPressed: _busy ? null : _lock,
                      semanticHint: 'Lock the device',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.lock_open_rounded,
                      label: 'Unlock',
                      color: scheme.tertiary,
                      onColor: scheme.onTertiary,
                      onPressed: _busy ? null : _unlock,
                      semanticHint: 'Unlock the device',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Refresh button
              OutlinedButton.icon(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Status'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _openProvisioning,
                icon: const Icon(Icons.wifi_tethering_rounded),
                label: const Text('Set Up / Reconnect Device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A large, accessible action button with icon and label.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
    required this.onPressed,
    this.semanticHint,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  final VoidCallback? onPressed;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: semanticHint,
      child: Material(
        color: color.withValues(alpha: onPressed == null ? 0.3 : 1.0),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Container(
            height: 80,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: onColor, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: onColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (icon, label, color, semanticStatus) = switch (state) {
      _Status.locked => (
        Icons.lock_rounded,
        'LOCKED',
        scheme.primary,
        'Device is locked',
      ),
      _Status.unlocked => (
        Icons.lock_open_rounded,
        'UNLOCKED',
        scheme.tertiary,
        'Device is unlocked',
      ),
      _Status.unknown => (
        Icons.help_outline_rounded,
        'UNKNOWN',
        scheme.outline,
        'Device status unknown',
      ),
    };

    return Semantics(
      label: semanticStatus,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              // Animated status icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(state),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
              ),
              const SizedBox(height: 16),
              // App name
              Text(
                appName,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              // Status label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Connection info
              Text(
                '$host:$port',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // Progress / last updated
              SizedBox(
                height: 20,
                child: busy
                    ? SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(),
                        ),
                      )
                    : Text(
                        lastUpdated == null
                            ? 'Not fetched yet'
                            : 'Updated ${_formatTime(lastUpdated!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
  }
}
