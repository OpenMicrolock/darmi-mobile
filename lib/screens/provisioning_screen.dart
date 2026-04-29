import 'package:flutter/material.dart';

import '../api/lock_api.dart';
import '../settings/settings_store.dart';

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
  ProvisioningConfig? _remoteConfig;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _hostCtl = TextEditingController(
      text: initial?.host ?? '',
    );
    _wifiSsidCtl = TextEditingController(text: initial?.wifiSsid ?? '');
    _wifiPasswordCtl = TextEditingController(
      text: initial?.wifiPassword ?? '',
    );
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
    final base =
        widget.initial ??
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

    setState(() => _statusMessage = null);

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
        _statusMessage = 'Loaded current device config from $host.';
      });

      await widget.store.save(merged);
    } on LockApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Could not load device config: ${e.message}';
      });
    } finally {
      api.dispose();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _statusMessage = null;
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
        _statusMessage = 'Configuration saved. The device is reconfiguring now.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved. The device is reconnecting.'),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on LockApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Could not save device config: ${e.message}';
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
      appBar: AppBar(title: const Text('Set Up Device'), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Connect your phone to the device hotspot, then enter the Wi-Fi you want the lock to join.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostCtl,
                decoration: const InputDecoration(
                  labelText: 'Device host',
                  hintText: 'Device AP IP or hostname',
                  prefixIcon: Icon(Icons.router_rounded),
                ),
                onFieldSubmitted: (_) => _loadFromDevice(),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Target Wi-Fi',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wifiSsidCtl,
                decoration: const InputDecoration(
                  labelText: 'Wi-Fi SSID',
                  hintText: 'MyHomeWiFi',
                  prefixIcon: Icon(Icons.wifi_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wifiPasswordCtl,
                decoration: InputDecoration(
                  labelText: 'Wi-Fi password',
                  hintText: _remoteConfig?.wifiHasPassword == true
                      ? 'Enter a new password if needed'
                      : 'Enter the target Wi-Fi password',
                  prefixIcon: const Icon(Icons.password_rounded),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ExpansionTile(
                initiallyExpanded: _advancedOpen,
                onExpansionChanged: (value) => setState(() {
                  _advancedOpen = value;
                }),
                title: Text(
                  'Advanced AP settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
                subtitle: const Text('Optional'),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apSsidCtl,
                    decoration: const InputDecoration(
                      labelText: 'AP SSID',
                      hintText: 'Device-Setup',
                      prefixIcon: Icon(Icons.settings_input_antenna_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apPasswordCtl,
                    decoration: InputDecoration(
                      labelText: 'AP password',
                      hintText: _remoteConfig?.apHasPassword == true
                          ? 'Enter a new password if needed'
                          : 'At least 8 characters or empty',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                    ),
                    obscureText: true,
                    validator: (value) {
                      final length = (value ?? '').length;
                      if (length > 0 && length < 8) {
                        return 'Must be at least 8 characters or empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _apBroadcastSsid,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Broadcast AP SSID'),
                    subtitle: Text(
                      _apBroadcastSsid
                          ? 'The hotspot is visible.'
                          : 'The hotspot is hidden.',
                    ),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _apBroadcastSsid = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_statusMessage != null) ...[
                Text(
                  _statusMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Saving...' : 'Save & Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
