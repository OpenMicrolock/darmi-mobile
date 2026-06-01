import 'package:flutter/material.dart';

import '../api/lock_api.dart';
import '../settings/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key, required this.store, this.initial});

  final SettingsStore store;
  final LockSettings? initial;

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostCtl;
  late final TextEditingController _wifiSsidCtl;
  late final TextEditingController _wifiPasswordCtl;
  late final TextEditingController _apSsidCtl;
  late final TextEditingController _apPasswordCtl;

  bool _apBroadcastSsid = true;
  bool _saving = false;
  bool _advancedOpen = false;
  String? _statusMessage;
  bool _statusSuccess = true;
  ProvisioningConfig? _remoteConfig;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _hostCtl = TextEditingController(text: initial?.host ?? '');
    _wifiSsidCtl = TextEditingController(text: initial?.wifiSsid ?? '');
    _wifiPasswordCtl = TextEditingController(text: initial?.wifiPassword ?? '');
    _apSsidCtl = TextEditingController(text: initial?.apSsid ?? '');
    _apPasswordCtl = TextEditingController(text: initial?.apPassword ?? '');
    _apBroadcastSsid = initial?.apBroadcastSsid ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromDevice());
  }

  @override
  void dispose() {
    _hostCtl.dispose();
    _wifiSsidCtl.dispose();
    _wifiPasswordCtl.dispose();
    _apSsidCtl.dispose();
    _apPasswordCtl.dispose();
    super.dispose();
  }

  LockSettings _buildSettings() {
    final base = widget.initial ??
        const LockSettings(
          host: '',
          port: LockSettings.defaultPort,
          token: '',
          hideSsidInApMode: false,
        );

    return base.copyWith(
      host: _hostCtl.text.trim(),
      port: LockSettings.defaultPort,
      wifiSsid: _wifiSsidCtl.text.trim(),
      wifiPassword: _wifiPasswordCtl.text,
      apSsid: _apSsidCtl.text.trim(),
      apPassword: _apPasswordCtl.text,
      apBroadcastSsid: _apBroadcastSsid,
      hideSsidInApMode: widget.initial?.hideSsidInApMode ?? false,
    );
  }

  LockApi _buildApi() {
    final base = widget.initial;
    return LockApi(
      host: _hostCtl.text.trim(),
      port: LockSettings.defaultPort,
      token: base?.token ?? '',
    );
  }

  Future<void> _loadFromDevice() async {
    final host = _hostCtl.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _statusMessage = 'Fetching device configuration...';
      _statusSuccess = true;
    });

    final api = _buildApi();
    try {
      final config = await api.getProvisioningConfig();
      final merged = _buildSettings().copyWith(
        wifiSsid: config.wifiSsid,
        apSsid: config.apSsid,
        apBroadcastSsid: config.apBroadcastSsid,
        hideSsidInApMode: _buildSettings().hideSsidInApMode,
      );

      _wifiSsidCtl.text = config.wifiSsid;
      _apSsidCtl.text = config.apSsid;

      setState(() {
        _remoteConfig = config;
        _apBroadcastSsid = config.apBroadcastSsid;
        _statusMessage = 'Connected to $host. Device configuration loaded.';
        _statusSuccess = true;
      });

      await widget.store.save(merged);
    } on LockApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Could not load configuration: ${e.message}';
        _statusSuccess = false;
      });
    } finally {
      api.dispose();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _statusMessage = 'Sending settings to device...';
      _statusSuccess = true;
    });

    final api = _buildApi();
    final draft = _buildSettings();

    try {
      final config = await api.updateProvisioningConfig(
        wifiSsid: draft.wifiSsid,
        wifiPassword: draft.wifiPassword,
        apSsid: draft.apSsid,
        apPassword: draft.apPassword,
        apBroadcastSsid: draft.apBroadcastSsid,
      );

      final saved = draft.copyWith(
        wifiSsid: config.wifiSsid,
        apSsid: config.apSsid,
        apBroadcastSsid: config.apBroadcastSsid,
        hideSsidInApMode: draft.hideSsidInApMode,
      );

      await widget.store.save(saved);

      if (!mounted) return;
      setState(() {
        _remoteConfig = config;
        _statusMessage = 'Settings saved successfully. The device is reconfiguring.';
        _statusSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved. The device is reconnecting now.'),
        ),
      );

      Navigator.of(context).pop(saved);
    } on LockApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to update configuration: ${e.message}';
        _statusSuccess = false;
      });
    } finally {
      api.dispose();
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Configuration'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Instructions Card
              Card(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.settings_input_antenna_rounded,
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Provisioning Guide',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Connect your phone to the ESP32 access point hotspot first, then enter the target Wi-Fi network credentials below.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Host Configuration Section
              _buildSectionHeader('Device Connection'),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _hostCtl,
                decoration: const InputDecoration(
                  labelText: 'Device Host IP / Domain',
                  hintText: 'e.g. 192.168.4.1',
                  prefixIcon: Icon(Icons.router_rounded),
                ),
                onFieldSubmitted: (_) => _loadFromDevice(),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Device host address is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Target Wi-Fi Section
              _buildSectionHeader('Target Wi-Fi Network'),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _wifiSsidCtl,
                        decoration: const InputDecoration(
                          labelText: 'Wi-Fi SSID',
                          hintText: 'Your Home Network Name',
                          prefixIcon: Icon(Icons.wifi_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _wifiPasswordCtl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Wi-Fi Password',
                          hintText: _remoteConfig?.wifiHasPassword == true
                              ? 'Saved (Enter new to override)'
                              : 'Password for your Wi-Fi network',
                          prefixIcon: const Icon(Icons.password_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Advanced AP Settings Section
              ExpansionTile(
                initiallyExpanded: _advancedOpen,
                onExpansionChanged: (value) => setState(() {
                  _advancedOpen = value;
                }),
                title: Text(
                  'Advanced Hotspot (AP) Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Optional settings for the device access point'),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _apSsidCtl,
                    decoration: const InputDecoration(
                      labelText: 'Device AP SSID',
                      prefixIcon: Icon(Icons.wifi_tethering_rounded),
                    ),
                    validator: (value) {
                      if (_advancedOpen && (value ?? '').trim().isEmpty) {
                        return 'AP SSID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _apPasswordCtl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Device AP Password',
                      hintText: _remoteConfig?.apHasPassword == true
                          ? 'Saved (Enter new to override)'
                          : 'Must be at least 8 characters',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                    ),
                    validator: (value) {
                      if (_advancedOpen) {
                        final len = (value ?? '').length;
                        if (len > 0 && len < 8) {
                          return 'Must be at least 8 characters or empty';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    value: _apBroadcastSsid,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Broadcast SSID'),
                    subtitle: Text(
                      _apBroadcastSsid
                          ? 'The device setup hotspot is visible to others.'
                          : 'The setup hotspot is hidden; requires manual connection.',
                    ),
                    onChanged: _saving
                        ? null
                        : (val) => setState(() => _apBroadcastSsid = val),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Status message banner
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _statusSuccess
                        ? AppColors.success.withValues(alpha: 0.1)
                        : scheme.errorContainer,
                    borderRadius: AppRadius.cardBorder,
                    border: Border.all(
                      color: _statusSuccess
                          ? AppColors.success.withValues(alpha: 0.25)
                          : scheme.error,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                        color: _statusSuccess ? AppColors.success : scheme.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusSuccess ? AppColors.success : scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Actions Button
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Saving Config...' : 'Apply & Connect'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
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
