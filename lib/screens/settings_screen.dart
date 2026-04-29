import 'package:flutter/material.dart';

import '../settings/lock_settings_sync_strategy.dart';
import '../settings/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store, this.initial});

  final SettingsStore store;
  final LockSettings? initial;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _syncStrategyFactory = const LockSettingsSyncStrategyFactory();
  late final TextEditingController _hostCtl;
  late final TextEditingController _tokenCtl;
  bool _obscureToken = true;
  bool _hideSsidInApMode = false;
  bool _loadingLockSettings = false;
  bool _savingApVisibility = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hostCtl = TextEditingController(
      text: widget.initial?.host ?? '192.168.4.1',
    );
    _tokenCtl = TextEditingController(text: widget.initial?.token ?? '');
    _hideSsidInApMode = widget.initial?.hideSsidInApMode ?? false;

    final syncStrategy = _syncStrategyFactory.create(widget.initial);
    if (widget.initial != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadLockSettings(syncStrategy, widget.initial!),
      );
    }
  }

  @override
  void dispose() {
    _hostCtl.dispose();
    _tokenCtl.dispose();
    super.dispose();
  }

  LockSettings _buildDraftSettings() {
    return LockSettings(
      host: _hostCtl.text.trim(),
      port: 1212,
      token: _tokenCtl.text,
      hideSsidInApMode: _hideSsidInApMode,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = _buildDraftSettings();
    final syncStrategy = _syncStrategyFactory.create(draft);

    try {
      final settings = await syncStrategy.save(draft);
      await widget.store.save(settings);
      if (!mounted) return;
      Navigator.of(context).pop(settings);
    } on LockSettingsSyncException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveApVisibility(bool hideSsidInApMode) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _savingApVisibility = true);
    final draft = _buildDraftSettings().copyWith(
      hideSsidInApMode: hideSsidInApMode,
    );
    final syncStrategy = _syncStrategyFactory.create(draft);

    try {
      final settings = await syncStrategy.save(draft);
      await widget.store.save(settings);
      if (!mounted) return;
      setState(() => _hideSsidInApMode = settings.hideSsidInApMode);
    } on LockSettingsSyncException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _savingApVisibility = false);
      }
    }
  }

  Future<void> _loadLockSettings(
    LockSettingsSyncStrategy syncStrategy,
    LockSettings settings,
  ) async {
    setState(() => _loadingLockSettings = true);

    try {
      final syncedSettings = await syncStrategy.load(settings);
      if (!mounted) return;
      setState(() => _hideSsidInApMode = syncedSettings.hideSsidInApMode);
    } on LockSettingsSyncException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _loadingLockSettings = false);
      }
    }
  }

  Future<void> _openAccessPointDialog() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete host and token first.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleToggle(bool value) async {
              setDialogState(() {});
              await _saveApVisibility(value);
              if (!mounted) return;
              setDialogState(() {});
            }

            return AlertDialog(
              title: const Text('AP Visibility'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hideSsidInApMode
                        ? 'The lock Wi-Fi is hidden in AP mode.'
                        : 'The lock Wi-Fi is visible in AP mode.',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _hideSsidInApMode,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hide SSID in AP mode'),
                    subtitle: const Text(
                      'Users must join the network manually from phone Wi-Fi settings.',
                    ),
                    onChanged: (_savingApVisibility || _loadingLockSettings)
                        ? null
                        : handleToggle,
                  ),
                  if (_savingApVisibility) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _savingApVisibility
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Device Settings'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Connection',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
                // Host field
                Semantics(
                  label: 'Device IP address or hostname',
                  child: TextFormField(
                    controller: _hostCtl,
                    decoration: const InputDecoration(
                      labelText: 'Device IP or hostname',
                      hintText: '192.168.4.1',
                      prefixIcon: Icon(Icons.dns_rounded),
                    ),
                    style: theme.textTheme.bodyLarge,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Authentication',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
                // Token field
                Semantics(
                  label: 'Authentication token',
                  child: TextFormField(
                    controller: _tokenCtl,
                    decoration: InputDecoration(
                      labelText: 'Auth token',
                      hintText: 'See device sticker or serial output',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureToken
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        tooltip: _obscureToken ? 'Show token' : 'Hide token',
                        onPressed: () =>
                            setState(() => _obscureToken = !_obscureToken),
                      ),
                    ),
                    style: theme.textTheme.bodyLarge,
                    obscureText: _obscureToken,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Access Point',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onTap:
                        (_saving || _loadingLockSettings || _savingApVisibility)
                        ? null
                        : _openAccessPointDialog,
                    leading: const Icon(Icons.wifi_tethering_rounded),
                    title: const Text('AP visibility'),
                    subtitle: Text(
                      _hideSsidInApMode ? 'Hidden network' : 'Visible network',
                    ),
                    trailing: (_loadingLockSettings || _savingApVisibility)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                // Save button
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving…' : 'Save Settings'),
                ),
                const SizedBox(height: 16),
                // Help text
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AP mode default: 192.168.4.1\nIf the SSID is hidden, join it manually from your phone Wi-Fi settings.\nIn STA mode, use the IP printed on the device serial.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
