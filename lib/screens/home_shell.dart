import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings/settings_store.dart';
import '../widgets/device_avatar.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'control_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';
import 'setup_wizard.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.store,
    required this.initialSettings,
  });

  final SettingsStore store;
  final LockSettings initialSettings;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late LockSettings _settings;
  List<LockSettings> _devices = const [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final list = await widget.store.loadDevices();
    if (mounted) {
      setState(() {
        _devices = list;
        // Verify if active settings is still in list or update it
        final activeExists = list.any((d) => d.id == _settings.id);
        if (list.isNotEmpty && !activeExists) {
          _settings = list.first;
        }
      });
    }
  }

  Future<void> _switchDevice(LockSettings device) async {
    if (device.id == _settings.id) return;
    
    HapticFeedback.selectionClick();
    final active = await widget.store.setActiveDevice(device.id);
    if (active != null && mounted) {
      setState(() {
        _settings = active;
      });
    }
  }

  void _onSettingsSaved(LockSettings updated) {
    setState(() {
      _settings = updated;
    });
    _loadDevices();
  }

  void _showDeviceSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: AppRadius.pillBorder,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text(
                    'Select Active Device',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected = device.id == _settings.id;

                      return ListTile(
                        leading: DeviceAvatar(
                          deviceType: device.deviceType,
                          isActive: isSelected,
                        ),
                        title: Text(
                          device.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                        subtitle: Text(
                          '${device.deviceType == 'lamp' ? 'Lamp' : 'Lock'} \u00b7 ${device.host}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight)
                            : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          _switchDevice(device);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.sm,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final saved = await Navigator.of(context).push<LockSettings>(
                        MaterialPageRoute(builder: (_) => const SetupWizard()),
                      );
                      if (saved != null) {
                        final persisted = await widget.store.save(saved);
                        _onSettingsSaved(persisted);
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add New Device'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Control', 'Devices', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: _tabIndex == 0
            ? GestureDetector(
                onTap: _showDeviceSelectorSheet,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DeviceAvatar(
                        deviceType: _settings.deviceType,
                        size: 32,
                        isActive: true,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _settings.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )
            : Text(titles[_tabIndex]),
        actions: _tabIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<LockSettings>(
                      MaterialPageRoute(builder: (_) => const SetupWizard()),
                    );
                    if (saved != null) {
                      final persisted = await widget.store.save(saved);
                      _onSettingsSaved(persisted);
                    }
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            ControlScreen(
              store: widget.store,
              settings: _settings,
              onSwitchDevice: _switchDevice,
            ),
            DevicesScreen(
              store: widget.store,
              devices: _devices,
              activeId: _settings.id,
              onSwitchDevice: _switchDevice,
              onDevicesChanged: _loadDevices,
            ),
            SettingsScreen(
              store: widget.store,
              activeDevice: _settings,
              onSettingsSaved: _onSettingsSaved,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _tabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices_rounded),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
