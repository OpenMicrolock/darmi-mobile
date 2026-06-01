import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../settings/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'device_edit_screen.dart';
import 'provisioning_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.activeDevice,
    required this.onSettingsSaved,
  });

  final SettingsStore store;
  final LockSettings activeDevice;
  final ValueChanged<LockSettings> onSettingsSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _darkMode = true;
  bool _hapticEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final darkVal = await _storage.read(key: 'pref_dark_mode');
    final hapticVal = await _storage.read(key: 'pref_haptic_enabled');

    if (mounted) {
      setState(() {
        _darkMode = darkVal != 'false'; // default true
        _hapticEnabled = hapticVal != 'false'; // default true
        _loading = false;
      });
    }
  }

  Future<void> _savePreference(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Section: App Preferences
            _buildSectionHeader('App Preferences'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode (Default)'),
                    subtitle: const Text('Keep UI matching dark background'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: _darkMode,
                    onChanged: (val) {
                      setState(() {
                        _darkMode = val;
                      });
                      _savePreference('pref_dark_mode', val.toString());
                      // In a real app we would notify a ThemeProvider, but since
                      // Dark Mode is default, we can keep the preference updated.
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Vibrate device on key actions'),
                    secondary: const Icon(Icons.vibration_rounded),
                    value: _hapticEnabled,
                    onChanged: (val) {
                      setState(() {
                        _hapticEnabled = val;
                      });
                      _savePreference('pref_haptic_enabled', val.toString());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section: Active Device Quick Configuration
            _buildSectionHeader('Active Device'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.activeDevice.deviceType == 'lamp'
                              ? Icons.lightbulb_outline_rounded
                              : Icons.lock_outline_rounded,
                          color: AppColors.primaryLight,
                          size: AppIconSize.md,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.activeDevice.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${widget.activeDevice.host}:${widget.activeDevice.port}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final saved = await Navigator.of(context).push<LockSettings>(
                                MaterialPageRoute(
                                  builder: (_) => DeviceEditScreen(
                                    store: widget.store,
                                    device: widget.activeDevice,
                                  ),
                                ),
                              );
                              if (saved != null) {
                                widget.onSettingsSaved(saved);
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit Info'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final saved = await Navigator.of(context).push<LockSettings>(
                                MaterialPageRoute(
                                  builder: (_) => ProvisioningScreen(
                                    store: widget.store,
                                    initial: widget.activeDevice,
                                  ),
                                ),
                              );
                              if (saved != null) {
                                widget.onSettingsSaved(saved);
                              }
                            },
                            icon: const Icon(Icons.wifi_tethering_rounded, size: 16),
                            label: const Text('Wi-Fi / AP'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section: About / IoT Stack Info
            _buildSectionHeader('About'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Microlock App'),
                    subtitle: const Text('Version 1.0.0 (ESP32 Smart Controller)'),
                    trailing: Text(
                      'v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.developer_board_rounded),
                    title: Text('PlatformIO + ESP-IDF Stack'),
                    subtitle: Text('Micro-controller server client architecture'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Open Source Licenses'),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Microlock',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
