import 'package:flutter/material.dart';
import '../settings/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DeviceEditScreen extends StatefulWidget {
  const DeviceEditScreen({
    super.key,
    required this.store,
    required this.device,
  });

  final SettingsStore store;
  final LockSettings device;

  @override
  State<DeviceEditScreen> createState() => _DeviceEditScreenState();
}

class _DeviceEditScreenState extends State<DeviceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtl;
  late final TextEditingController _hostCtl;
  late final TextEditingController _portCtl;
  late final TextEditingController _tokenCtl;
  late String _type;
  bool _obscureToken = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.device.name);
    _hostCtl = TextEditingController(text: widget.device.host);
    _portCtl = TextEditingController(text: widget.device.port.toString());
    _tokenCtl = TextEditingController(text: widget.device.token);
    _type = widget.device.deviceType;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final port = int.tryParse(_portCtl.text) ?? LockSettings.defaultPort;
    final updated = widget.device.copyWith(
      name: _nameCtl.text.trim(),
      host: _hostCtl.text.trim(),
      port: port,
      token: _tokenCtl.text,
      deviceType: _type,
    );

    try {
      final saved = await widget.store.save(updated);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save device: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.device.name}'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Segmented type selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'lock',
                    icon: Icon(Icons.lock_outline_rounded),
                    label: Text('Smart Lock'),
                  ),
                  ButtonSegment(
                    value: 'lamp',
                    icon: Icon(Icons.lightbulb_outline_rounded),
                    label: Text('Smart Lamp'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Name Input
              TextFormField(
                controller: _nameCtl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'Front Door',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Device name is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Host Input
              TextFormField(
                controller: _hostCtl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'IP Address / Host',
                  hintText: '192.168.1.100',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'IP Address is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Port Input
              TextFormField(
                controller: _portCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '1212',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                validator: (value) {
                  final p = int.tryParse(value ?? '');
                  if (p == null || p <= 0 || p > 65535) {
                    return 'Please enter a valid port (1-65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Auth Token Input
              TextFormField(
                controller: _tokenCtl,
                obscureText: _obscureToken,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Auth Token',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureToken = !_obscureToken),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) return 'Authentication token is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Save Button
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
              const SizedBox(height: AppSpacing.md),

              Center(
                child: Text(
                  'Connected via secure token settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
