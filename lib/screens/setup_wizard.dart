import 'package:flutter/material.dart';

import '../api/lock_api.dart';
import '../settings/settings_store.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  int _step = 0;
  String _type = 'lock';
  final _nameCtl = TextEditingController();
  final _hostCtl = TextEditingController(text: '127.0.0.1');
  final _portCtl = TextEditingController(text: '1212');
  final _tokenCtl = TextEditingController();
  bool _obscureToken = true;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _hostCtl.dispose();
    _portCtl.dispose();
    _tokenCtl.dispose();
    super.dispose();
  }

  int get _port => int.tryParse(_portCtl.text) ?? 0;

  bool get _canProceed {
    return switch (_step) {
      0 => true,
      1 => _nameCtl.text.trim().isNotEmpty && _hostCtl.text.trim().isNotEmpty && _port > 0 && _port <= 65535,
      2 => _tokenCtl.text.isNotEmpty,
      3 => true,
      4 => true,
      _ => false,
    };
  }

  LockSettings get _draft => LockSettings(
    name: _nameCtl.text.trim(),
    host: _hostCtl.text.trim(),
    port: _port,
    token: _tokenCtl.text,
    deviceType: _type,
  );

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    try {
      final api = LockApi(
        host: _draft.host,
        port: _draft.port,
        token: _draft.token,
        deviceType: _type == 'lamp' ? DeviceType.lamp : DeviceType.lock,
      );
      await api.ping();
      api.dispose();
      setState(() { _testResult = 'Device Connected'; _testSuccess = true; });
    } on UnauthorizedException {
      setState(() { _testResult = 'Wrong token'; _testSuccess = false; });
    } on LockApiException catch (e) {
      setState(() { _testResult = e.message; _testSuccess = false; });
    } catch (e) {
      setState(() { _testResult = 'Connection Failed'; _testSuccess = false; });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _finish() {
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Set up device ($_step/4)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildStep(theme, scheme)),
              const SizedBox(height: 16),
              _buildNavigation(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, ColorScheme scheme) {
    return switch (_step) {
      0 => _StepSelectType(scheme, _type, (t) => setState(() => _type = t)),
      1 => _StepInfo(_nameCtl, _hostCtl, _portCtl),
      2 => _StepAuth(_tokenCtl, _obscureToken, () => setState(() => _obscureToken = !_obscureToken)),
      3 => _StepTest(_testing, _testResult, _testSuccess, _testConnection),
      4 => _StepSave(_draft, _finish),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildNavigation(ColorScheme scheme) {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              child: const Text('Back'),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _canProceed
                ? () {
                    if (_step < 4) {
                      setState(() => _step++);
                    }
                  }
                : null,
            child: Text(_step < 4 ? 'Next' : 'Done'),
          ),
        ),
      ],
    );
  }
}

class _StepSelectType extends StatelessWidget {
  const _StepSelectType(this.scheme, this.selected, this.onChanged);
  final ColorScheme scheme;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Choose device type', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 32),
        _TypeCard(
          icon: Icons.lock_outline,
          label: 'Smart Lock',
          selected: selected == 'lock',
          onTap: () => onChanged('lock'),
        ),
        const SizedBox(height: 16),
        _TypeCard(
          icon: Icons.lightbulb_outline,
          label: 'Smart Lamp',
          selected: selected == 'lamp',
          onTap: () => onChanged('lamp'),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 48, color: selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? scheme.primary : null,
                fontWeight: selected ? FontWeight.w600 : null,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepInfo extends StatelessWidget {
  const _StepInfo(this.nameCtl, this.hostCtl, this.portCtl);
  final TextEditingController nameCtl;
  final TextEditingController hostCtl;
  final TextEditingController portCtl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Device Information', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        TextField(
          controller: nameCtl,
          decoration: const InputDecoration(labelText: 'Device name', hintText: 'Front Door', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: hostCtl,
          decoration: const InputDecoration(labelText: 'IP Address', hintText: '127.0.0.1', border: OutlineInputBorder()),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: portCtl,
          decoration: const InputDecoration(labelText: 'Port', hintText: '1212', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

class _StepAuth extends StatelessWidget {
  const _StepAuth(this.tokenCtl, this.obscure, this.toggleVisibility);
  final TextEditingController tokenCtl;
  final bool obscure;
  final VoidCallback toggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Authentication', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        TextField(
          controller: tokenCtl,
          decoration: InputDecoration(
            labelText: 'Token',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: toggleVisibility,
            ),
          ),
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          autofocus: true,
        ),
      ],
    );
  }
}

class _StepTest extends StatelessWidget {
  const _StepTest(this.testing, this.result, this.success, this.onTest);
  final bool testing;
  final String? result;
  final bool success;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Test Connection', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: testing ? null : onTest,
            icon: testing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_find),
            label: Text(testing ? 'Testing\u2026' : 'Test Connection'),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.green : scheme.error),
              const SizedBox(width: 8),
              Text(result!, style: TextStyle(color: success ? Colors.green : scheme.error)),
            ],
          ),
        ],
      ],
    );
  }
}

class _StepSave extends StatelessWidget {
  const _StepSave(this.draft, this.onSave);
  final LockSettings draft;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(draft.deviceType == 'lamp' ? Icons.lightbulb_outline : Icons.lock_outline, size: 64, color: scheme.primary),
        const SizedBox(height: 16),
        Text(draft.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${draft.deviceType == 'lamp' ? 'Lamp' : 'Lock'} \u00b7 ${draft.host}:${draft.port}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check),
            label: const Text('Save Device'),
          ),
        ),
      ],
    );
  }
}
