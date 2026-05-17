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

  List<LockSettings> _devices = const [];
  int _selectedIndex = 0;
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
    _loadDevices();
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
        _state = s == DeviceLockState.locked
            ? _Status.locked
            : _Status.unlocked;
        _lastUpdated = DateTime.now();
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _error = 'Unauthorized — update your token';
        _selectedIndex = 2;
      });
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

  Future<void> _loadDevices() async {
    final devices = await widget.store.loadDevices();
    if (!mounted) return;
    setState(() {
      _devices = devices;
    });
  }

  void _applySettings(LockSettings updated) {
    _api.dispose();
    setState(() {
      _settings = updated;
      _devices = _upsertDevice(_devices, updated);
      _api = _buildApi();
      _state = _Status.unknown;
      _error = null;
      _selectedIndex = 0;
    });
    _refresh();
  }

  Future<void> _selectDevice(LockSettings device) async {
    final active = await widget.store.setActiveDevice(device.id);
    if (active == null || !mounted || active.id == _settings.id) return;
    _api.dispose();
    setState(() {
      _settings = active;
      _api = _buildApi();
      _state = _Status.unknown;
      _error = null;
      _lastUpdated = null;
      _selectedIndex = 0;
    });
    _refresh();
  }

  Future<void> _addDevice() async {
    final saved = await Navigator.of(context).push<LockSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          store: widget.store,
          initial: const LockSettings(
            name: '',
            host: '192.168.4.1',
            port: LockSettings.defaultPort,
            token: '',
          ),
        ),
      ),
    );
    if (saved != null) _applySettings(saved);
  }

  Future<void> _editDevice(LockSettings device) async {
    final saved = await Navigator.of(context).push<LockSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(store: widget.store, initial: device),
      ),
    );
    if (saved != null) _applySettings(saved);
  }

  Future<void> _deleteDevice(LockSettings device) async {
    if (_devices.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one device.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete device?'),
        content: Text('Remove ${device.name} from this app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final active = await widget.store.deleteDevice(device.id);
    final devices = await widget.store.loadDevices();
    if (!mounted) return;

    if (active == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SettingsScreen(store: widget.store)),
      );
      return;
    }

    final deletedActive = device.id == _settings.id;
    if (deletedActive) {
      _api.dispose();
      setState(() {
        _settings = active;
        _devices = devices;
        _api = _buildApi();
        _state = _Status.unknown;
        _error = null;
        _lastUpdated = null;
        _selectedIndex = 0;
      });
      _refresh();
    } else {
      setState(() {
        _devices = devices;
      });
    }
  }

  List<LockSettings> _upsertDevice(
    List<LockSettings> devices,
    LockSettings updated,
  ) {
    final next = [...devices];
    final index = next.indexWhere((device) => device.id == updated.id);
    if (index == -1) {
      next.add(updated);
    } else {
      next[index] = updated;
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_selectedIndex) {
      0 => 'Microlock',
      1 => 'Devices',
      _ => 'Device settings',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeTab(
              state: _state,
              busy: _busy,
              error: _error,
              lastUpdated: _lastUpdated,
              deviceName: _settings.name,
              host: _settings.host,
              port: _settings.port,
              onRefresh: _refresh,
              onLock: _lock,
              onUnlock: _unlock,
            ),
            _DevicesTab(
              devices: _devices,
              activeDeviceId: _settings.id,
              onAddDevice: _addDevice,
              onSelectDevice: _selectDevice,
              onEditDevice: _editDevice,
              onDeleteDevice: _deleteDevice,
            ),
            DeviceSettingsForm(
              key: ValueKey(_settings.id),
              store: widget.store,
              initial: _settings,
              onSaved: _applySettings,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.state,
    required this.busy,
    required this.error,
    required this.lastUpdated,
    required this.deviceName,
    required this.host,
    required this.port,
    required this.onRefresh,
    required this.onLock,
    required this.onUnlock,
  });

  final _Status state;
  final bool busy;
  final String? error;
  final DateTime? lastUpdated;
  final String deviceName;
  final String host;
  final int port;
  final Future<void> Function() onRefresh;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          _StatusCard(
            state: state,
            busy: busy,
            lastUpdated: lastUpdated,
            deviceName: deviceName,
            host: host,
            port: port,
          ),
          const SizedBox(height: 24),
          if (error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
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
                  onPressed: busy ? null : onUnlock,
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
                  onPressed: busy ? null : onLock,
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
            onPressed: busy ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh status'),
          ),
        ],
      ),
    );
  }
}

class _DevicesTab extends StatelessWidget {
  const _DevicesTab({
    required this.devices,
    required this.activeDeviceId,
    required this.onAddDevice,
    required this.onSelectDevice,
    required this.onEditDevice,
    required this.onDeleteDevice,
  });

  final List<LockSettings> devices;
  final String activeDeviceId;
  final VoidCallback onAddDevice;
  final ValueChanged<LockSettings> onSelectDevice;
  final ValueChanged<LockSettings> onEditDevice;
  final ValueChanged<LockSettings> onDeleteDevice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: onAddDevice,
          icon: const Icon(Icons.add),
          label: const Text('Add device'),
        ),
        const SizedBox(height: 12),
        for (final device in devices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 0,
              child: ListTile(
                leading: Icon(
                  device.id == activeDeviceId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: device.id == activeDeviceId ? scheme.primary : null,
                ),
                title: Text(device.name),
                subtitle: Text('${device.host}:${device.port}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(device.id == activeDeviceId ? 'Active' : 'Tap to use'),
                    PopupMenuButton<_DeviceAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _DeviceAction.edit:
                            onEditDevice(device);
                          case _DeviceAction.delete:
                            onDeleteDevice(device);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _DeviceAction.edit,
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _DeviceAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: device.id == activeDeviceId
                    ? null
                    : () => onSelectDevice(device),
              ),
            ),
          ),
      ],
    );
  }
}

enum _DeviceAction { edit, delete }

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.busy,
    required this.lastUpdated,
    required this.deviceName,
    required this.host,
    required this.port,
  });

  final _Status state;
  final bool busy;
  final DateTime? lastUpdated;
  final String deviceName;
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
              child: Icon(icon, key: ValueKey(state), size: 96, color: color),
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
              deviceName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('$host:$port', style: Theme.of(context).textTheme.bodySmall),
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
