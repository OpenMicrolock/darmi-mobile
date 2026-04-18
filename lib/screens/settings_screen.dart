import 'package:flutter/material.dart';

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
  late final TextEditingController _hostCtl;
  late final TextEditingController _portCtl;
  late final TextEditingController _tokenCtl;
  bool _obscureToken = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hostCtl = TextEditingController(text: widget.initial?.host ?? '192.168.4.1');
    _portCtl = TextEditingController(
      text: (widget.initial?.port ?? 1212).toString(),
    );
    _tokenCtl = TextEditingController(text: widget.initial?.token ?? '');
  }

  @override
  void dispose() {
    _hostCtl.dispose();
    _portCtl.dispose();
    _tokenCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final settings = LockSettings(
      host: _hostCtl.text.trim(),
      port: int.parse(_portCtl.text.trim()),
      token: _tokenCtl.text,
    );
    await widget.store.save(settings);
    if (!mounted) return;
    Navigator.of(context).pop(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device settings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _hostCtl,
                  decoration: const InputDecoration(
                    labelText: 'Device IP or hostname',
                    hintText: '192.168.4.1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tokenCtl,
                  decoration: InputDecoration(
                    labelText: 'Auth token',
                    hintText: 'See device sticker or serial output',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureToken = !_obscureToken),
                    ),
                  ),
                  obscureText: _obscureToken,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save'),
                ),
                const SizedBox(height: 8),
                Text(
                  'AP mode default: 192.168.4.1. In STA mode, use the IP '
                  'printed on the device serial.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
