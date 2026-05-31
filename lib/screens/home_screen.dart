import 'dart:async';

import 'package:flutter/material.dart';

import '../api/lock_api.dart';
import '../settings/settings_store.dart';
import 'setup_wizard.dart';

enum _ConnectionStatus { unknown, active, inactive, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, required this.settings});

  final SettingsStore store;
  final LockSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LockSettings _settings;
  late LockApi _api;

  List<LockSettings> _devices = const [];
  int _tabIndex = 0;
  _ConnectionStatus _connection = _ConnectionStatus.unknown;
  String _stateLabel = '';
  bool _busy = false;
  String? _error;
  DateTime? _lastUpdated;

  Timer? _autoLockTimer;
  int _countdownRemaining = 0;

  bool get _isLamp => _settings.deviceType == 'lamp';
  bool get _isActive => _stateLabel == 'on' || _stateLabel == 'unlocked';

  String get _stateText {
    if (_stateLabel.isEmpty) return '--';
    if (_isLamp) return _stateLabel == 'on' ? 'ON' : 'OFF';
    return _stateLabel == 'locked' ? 'LOCKED' : 'UNLOCKED';
  }

  IconData get _stateIcon {
    if (_stateLabel.isEmpty) return Icons.help_outline;
    if (_isLamp) return _stateLabel == 'on' ? Icons.lightbulb : Icons.lightbulb_outline;
    return _stateLabel == 'locked' ? Icons.lock : Icons.lock_open;
  }

  Color _stateColor(ColorScheme scheme) {
    if (_stateLabel.isEmpty) return scheme.outline;
    if (_isLamp) return _stateLabel == 'on' ? const Color(0xFFFFA726) : scheme.outline;
    return _stateLabel == 'locked' ? scheme.primary : scheme.tertiary;
  }

  String get _primaryActionLabel {
    if (_isLamp) return _isActive ? 'OFF' : 'ON';
    return _isActive ? 'LOCK' : 'UNLOCK';
  }

  IconData get _primaryActionIcon {
    if (_isLamp) return _isActive ? Icons.power_settings_new : Icons.power_settings_new;
    return _isActive ? Icons.lock : Icons.lock_open;
  }

  String get _connectionText {
    return switch (_connection) {
      _ConnectionStatus.active => 'Active',
      _ConnectionStatus.inactive => 'Non Active',
      _ConnectionStatus.error => 'Error',
      _ConnectionStatus.unknown => 'Unknown',
    };
  }

  Color _connectionColor(ColorScheme scheme) {
    return switch (_connection) {
      _ConnectionStatus.active => Colors.green,
      _ConnectionStatus.inactive => Colors.red,
      _ConnectionStatus.error => Colors.orange,
      _ConnectionStatus.unknown => scheme.outline,
    };
  }

  LockApi _buildApi() => LockApi(
    host: _settings.host,
    port: _settings.port,
    token: _settings.token,
    deviceType: _isLamp ? DeviceType.lamp : DeviceType.lock,
  );

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _api = _buildApi();
    _loadDevices();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _cancelAutoLock();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final devices = await widget.store.loadDevices();
    if (mounted) setState(() => _devices = devices);
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_isLamp) {
        final s = await _api.lampStatus();
        _stateLabel = s == DeviceLampState.on ? 'on' : 'off';
      } else {
        final s = await _api.status();
        _stateLabel = s == DeviceLockState.locked ? 'locked' : 'unlocked';
      }
      _connection = _ConnectionStatus.active;
      _lastUpdated = DateTime.now();
    } on UnauthorizedException {
      _error = 'Wrong token';
      _connection = _ConnectionStatus.error;
    } on LockApiException catch (e) {
      _error = e.message;
      _connection = _ConnectionStatus.inactive;
    } catch (e) {
      _error = 'Connection failed';
      _connection = _ConnectionStatus.inactive;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _primaryAction() async {
    if (_busy || _stateLabel.isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_isLamp) {
        final s = _isActive ? await _api.turnOff() : await _api.turnOn();
        _stateLabel = s == DeviceLampState.on ? 'on' : 'off';
        _cancelAutoLock();
      } else {
        final s = _isActive ? await _api.lock() : await _api.unlock();
        _stateLabel = s == DeviceLockState.locked ? 'locked' : 'unlocked';
        if (!_isActive) {
          _cancelAutoLock();
        } else {
          _startAutoLock();
        }
      }
      _connection = _ConnectionStatus.active;
      _lastUpdated = DateTime.now();
    } on UnauthorizedException {
      _error = 'Wrong token';
      _connection = _ConnectionStatus.error;
    } on LockApiException catch (e) {
      _error = e.message;
      _connection = _ConnectionStatus.inactive;
    } catch (e) {
      _error = 'Connection failed';
      _connection = _ConnectionStatus.inactive;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startAutoLock() {
    _cancelAutoLock();
    _countdownRemaining = 5;
    if (mounted) setState(() {});
    _autoLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownRemaining--;
      if (_countdownRemaining <= 0) {
        timer.cancel();
        _autoLock();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  void _cancelAutoLock() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
    _countdownRemaining = 0;
  }

  Future<void> _autoLock() async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _autoLockTimer = null;
      _countdownRemaining = 0;
    });
    try {
      final s = await _api.lock();
      _stateLabel = s == DeviceLockState.locked ? 'locked' : 'unlocked';
      _connection = _ConnectionStatus.active;
      _lastUpdated = DateTime.now();
    } on UnauthorizedException {
      _error = 'Wrong token';
      _connection = _ConnectionStatus.error;
    } on LockApiException catch (e) {
      _error = e.message;
      _connection = _ConnectionStatus.inactive;
    } catch (e) {
      _error = 'Connection failed';
      _connection = _ConnectionStatus.inactive;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switchDevice(LockSettings device) async {
    final active = await widget.store.setActiveDevice(device.id);
    if (active == null || !mounted || active.id == _settings.id) return;
    _cancelAutoLock();
    _api.dispose();
    setState(() {
      _settings = active;
      _api = _buildApi();
      _stateLabel = '';
      _connection = _ConnectionStatus.unknown;
      _error = null;
      _lastUpdated = null;
      _tabIndex = 0;
    });
    _refresh();
  }

  void _onSettingsSaved(LockSettings updated) {
    _cancelAutoLock();
    _api.dispose();
    setState(() {
      _settings = updated;
      _devices = _upsertDevice(_devices, updated);
      _api = _buildApi();
      _stateLabel = '';
      _connection = _ConnectionStatus.unknown;
      _error = null;
      _tabIndex = 0;
    });
    _refresh();
  }

  Future<void> _addDevice() async {
    final saved = await Navigator.of(context).push<LockSettings>(
      MaterialPageRoute(builder: (_) => const SetupWizard()),
    );
    if (saved != null) {
      final persisted = await widget.store.save(saved);
      _onSettingsSaved(persisted);
    }
  }

  Future<void> _editDevice(LockSettings device) async {
    final saved = await Navigator.of(context).push<LockSettings>(
      MaterialPageRoute(
        builder: (_) => _DeviceEditScreen(store: widget.store, device: device),
      ),
    );
    if (saved != null) _onSettingsSaved(saved);
  }

  Future<void> _deleteDevice(LockSettings device) async {
    if (_devices.length <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keep at least one device')),
        );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete device?'),
        content: Text('Remove ${device.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final active = await widget.store.deleteDevice(device.id);
    final devices = await widget.store.loadDevices();
    if (!mounted) return;
    if (active == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupWizard()),
      );
      return;
    }
    if (device.id == _settings.id) {
      _cancelAutoLock();
      _api.dispose();
      setState(() {
        _settings = active;
        _devices = devices;
        _api = _buildApi();
        _stateLabel = '';
        _connection = _ConnectionStatus.unknown;
        _error = null;
        _lastUpdated = null;
        _tabIndex = 0;
      });
      _refresh();
    } else {
      setState(() => _devices = devices);
    }
  }

  List<LockSettings> _upsertDevice(List<LockSettings> devices, LockSettings updated) {
    final next = [...devices];
    final i = next.indexWhere((d) => d.id == updated.id);
    if (i == -1) { next.add(updated); } else { next[i] = updated; }
    return next;
  }

  String _formatTime(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titles = ['Home', 'Devices', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: _tabIndex == 0
            ? _DeviceSwitcher(
                devices: _devices,
                activeId: _settings.id,
                isLamp: _settings.deviceType == 'lamp',
                onChange: _switchDevice,
              )
            : Text(titles[_tabIndex]),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _ControlPanel(
              isLamp: _isLamp,
              stateIcon: _stateIcon,
              stateText: _stateText,
              stateColor: _stateColor(scheme),
              deviceName: _settings.name,
              connectionText: _connectionText,
              connectionColor: _connectionColor(scheme),
              busy: _busy,
              error: _error,
              lastUpdated: _lastUpdated,
              actionLabel: _primaryActionLabel,
              actionIcon: _primaryActionIcon,
              onAction: _primaryAction,
              onRefresh: _refresh,
              formatTime: _formatTime,
              countdownRemaining: _countdownRemaining,
              onCancelAutoLock: _cancelAutoLock,
            ),
            _DevicesList(
              devices: _devices,
              activeId: _settings.id,
              onAdd: _addDevice,
              onSelect: _switchDevice,
              onEdit: _editDevice,
              onDelete: _deleteDevice,
            ),
            _DeviceEditForm(
              settings: _settings,
              onSaved: _onSettingsSaved,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.devices_outlined), selectedIcon: Icon(Icons.devices), label: 'Devices'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _DeviceSwitcher extends StatelessWidget {
  const _DeviceSwitcher({
    required this.devices,
    required this.activeId,
    required this.isLamp,
    required this.onChange,
  });

  final List<LockSettings> devices;
  final String activeId;
  final bool isLamp;
  final ValueChanged<LockSettings> onChange;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: activeId,
        icon: const Icon(Icons.arrow_drop_down),
        isDense: true,
        style: Theme.of(context).textTheme.titleMedium,
        items: devices.map((d) {
          final lamp = d.deviceType == 'lamp';
          return DropdownMenuItem(
            value: d.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(lamp ? Icons.lightbulb_outline : Icons.lock_outline, size: 18),
                const SizedBox(width: 8),
                Text(d.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (id) {
          if (id != null) {
            onChange(devices.firstWhere((d) => d.id == id));
          }
        },
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.isLamp,
    required this.stateIcon,
    required this.stateText,
    required this.stateColor,
    required this.deviceName,
    required this.connectionText,
    required this.connectionColor,
    required this.busy,
    required this.error,
    required this.lastUpdated,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.onRefresh,
    required this.formatTime,
    required this.countdownRemaining,
    required this.onCancelAutoLock,
  });

  final bool isLamp;
  final IconData stateIcon;
  final String stateText;
  final Color stateColor;
  final String deviceName;
  final String connectionText;
  final Color connectionColor;
  final bool busy;
  final String? error;
  final DateTime? lastUpdated;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final VoidCallback onRefresh;
  final String Function(DateTime) formatTime;
  final int countdownRemaining;
  final VoidCallback onCancelAutoLock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: stateColor.withValues(alpha: 0.4), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(stateIcon, key: ValueKey(stateText), size: 96, color: stateColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stateText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(deviceName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 10, color: connectionColor),
                      const SizedBox(width: 4),
                      Text(connectionText, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 16,
                    child: busy
                        ? const LinearProgressIndicator()
                        : Text(
                            lastUpdated == null ? '' : 'Updated ${formatTime(lastUpdated!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                  ),
                  if (countdownRemaining > 0) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: countdownRemaining / 5.0,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-lock in ${countdownRemaining}s',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onCancelAutoLock,
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (error != null)
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!, style: TextStyle(color: scheme.onErrorContainer))),
                  ],
                ),
              ),
            ),
          if (error != null) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: busy || stateText == '--' ? null : onAction,
              icon: Icon(actionIcon),
              label: Text(actionLabel),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: busy ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicesList extends StatelessWidget {
  const _DevicesList({
    required this.devices,
    required this.activeId,
    required this.onAdd,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LockSettings> devices;
  final String activeId;
  final VoidCallback onAdd;
  final ValueChanged<LockSettings> onSelect;
  final ValueChanged<LockSettings> onEdit;
  final ValueChanged<LockSettings> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add device')),
        const SizedBox(height: 12),
        for (final device in devices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 0,
              child: ListTile(
                leading: Icon(
                  device.id == activeId ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: device.id == activeId ? scheme.primary : null,
                ),
                title: Row(
                  children: [
                    Icon(
                      device.deviceType == 'lamp' ? Icons.lightbulb_outline : Icons.lock_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(device.name),
                  ],
                ),
                subtitle: Text(device.deviceType == 'lamp' ? 'Lamp' : 'Lock'),
                trailing: PopupMenuButton<_Action>(
                  onSelected: (a) {
                    switch (a) { case _Action.edit: onEdit(device); case _Action.delete: onDelete(device); }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: _Action.edit, child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                    PopupMenuItem(value: _Action.delete, child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
                  ],
                ),
                onTap: device.id == activeId ? null : () => onSelect(device),
              ),
            ),
          ),
      ],
    );
  }
}

enum _Action { edit, delete }

class _DeviceEditScreen extends StatelessWidget {
  const _DeviceEditScreen({required this.store, required this.device});

  final SettingsStore store;
  final LockSettings device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: _DeviceEditForm(settings: device, onSaved: (saved) => Navigator.of(context).pop(saved)),
    );
  }
}

class _DeviceEditForm extends StatefulWidget {
  const _DeviceEditForm({required this.settings, required this.onSaved});

  final LockSettings settings;
  final ValueChanged<LockSettings> onSaved;

  @override
  State<_DeviceEditForm> createState() => _DeviceEditFormState();
}

class _DeviceEditFormState extends State<_DeviceEditForm> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _hostCtl;
  late final TextEditingController _portCtl;
  late final TextEditingController _tokenCtl;
  String _type = 'lock';
  bool _obscureToken = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.settings.name);
    _hostCtl = TextEditingController(text: widget.settings.host);
    _portCtl = TextEditingController(text: widget.settings.port.toString());
    _tokenCtl = TextEditingController(text: widget.settings.token);
    _type = widget.settings.deviceType;
  }

  @override
  void didUpdateWidget(_DeviceEditForm old) {
    super.didUpdateWidget(old);
    if (widget.settings.id != old.settings.id) {
      _nameCtl.text = widget.settings.name;
      _hostCtl.text = widget.settings.host;
      _portCtl.text = widget.settings.port.toString();
      _tokenCtl.text = widget.settings.token;
      _type = widget.settings.deviceType;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _hostCtl.dispose();
    _portCtl.dispose();
    _tokenCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final port = int.tryParse(_portCtl.text) ?? 0;
    if (_nameCtl.text.trim().isEmpty || _hostCtl.text.trim().isEmpty || port == 0 || _tokenCtl.text.isEmpty) return;
    setState(() => _saving = true);
    final updated = widget.settings.copyWith(
      name: _nameCtl.text.trim(),
      host: _hostCtl.text.trim(),
      port: port,
      token: _tokenCtl.text,
      deviceType: _type,
    );
    final store = SettingsStore();
    final saved = await store.save(updated);
    if (mounted) widget.onSaved(saved);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'lock', icon: Icon(Icons.lock_outline), label: Text('Lock')),
              ButtonSegment(value: 'lamp', icon: Icon(Icons.lightbulb_outline), label: Text('Lamp')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(labelText: 'Device name', hintText: 'Front Door', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hostCtl,
            decoration: const InputDecoration(labelText: 'Device IP', hintText: '127.0.0.1', border: OutlineInputBorder()),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portCtl,
            decoration: const InputDecoration(labelText: 'Port', hintText: '1212', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenCtl,
            decoration: InputDecoration(
              labelText: 'Auth token',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
            ),
            obscureText: _obscureToken,
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving\u2026' : 'Save'),
          ),
          const SizedBox(height: 8),
          Text(
            'Using token auth on port ${widget.settings.port}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
