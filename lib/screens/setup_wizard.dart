import 'package:flutter/material.dart';

import '../api/lock_api.dart';
import '../settings/settings_store.dart';
import '../widgets/step_indicator.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

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
    _pageController.dispose();
    _nameCtl.dispose();
    _hostCtl.dispose();
    _portCtl.dispose();
    _tokenCtl.dispose();
    super.dispose();
  }

  int get _port => int.tryParse(_portCtl.text) ?? 0;

  void _onFieldChanged() => setState(() {});

  bool get _canProceed {
    return switch (_step) {
      0 => true,
      1 => _nameCtl.text.trim().isNotEmpty &&
          _hostCtl.text.trim().isNotEmpty &&
          _port > 0 &&
          _port <= 65535,
      2 => _tokenCtl.text.isNotEmpty,
      3 => _testSuccess, // Must test and pass connection to save device
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
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final api = LockApi(
        host: _draft.host,
        port: _draft.port,
        token: _draft.token,
        deviceType: _type == 'lamp' ? DeviceType.lamp : DeviceType.lock,
      );
      await api.ping();
      api.dispose();
      setState(() {
        _testResult = 'Device Connected Successfully!';
        _testSuccess = true;
      });
    } on UnauthorizedException {
      setState(() {
        _testResult = 'Unauthorized: Wrong auth token';
        _testSuccess = false;
      });
    } on LockApiException catch (e) {
      setState(() {
        _testResult = e.message;
        _testSuccess = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Connection Failed: Device unreachable';
        _testSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _finish() {
    Navigator.of(context).pop(_draft);
  }

  void _nextPage() {
    if (_step < 4) {
      setState(() {
        _step++;
      });
      _pageController.animateToPage(
        _step,
        duration: AppDurations.normal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_step > 0) {
      setState(() {
        _step--;
      });
      _pageController.animateToPage(
        _step,
        duration: AppDurations.normal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: StepIndicator(currentStep: _step, totalSteps: 5),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Force wizard buttons
                  onPageChanged: (page) {
                    setState(() {
                      _step = page;
                    });
                  },
                  children: [
                    _StepSelectType(
                      selected: _type,
                      onChanged: (t) => setState(() => _type = t),
                    ),
                    _StepInfo(
                      nameCtl: _nameCtl,
                      hostCtl: _hostCtl,
                      portCtl: _portCtl,
                      onChanged: _onFieldChanged,
                    ),
                    _StepAuth(
                      tokenCtl: _tokenCtl,
                      obscure: _obscureToken,
                      toggleVisibility: () =>
                          setState(() => _obscureToken = !_obscureToken),
                      onChanged: _onFieldChanged,
                    ),
                    _StepTest(
                      testing: _testing,
                      result: _testResult,
                      success: _testSuccess,
                      onTest: _testConnection,
                    ),
                    _StepSave(
                      draft: _draft,
                      onSave: _finish,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: AppSpacing.screenPadding,
                child: _buildNavigation(scheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(ColorScheme scheme) {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevPage,
              child: const Text('Back'),
            ),
          ),
        if (_step > 0) const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: _canProceed
                ? () {
                    if (_step < 4) {
                      _nextPage();
                    } else {
                      _finish();
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
  const _StepSelectType({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Device Type',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Which ESP32 device type are you adding?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _TypeCard(
              icon: Icons.lock_outline_rounded,
              label: 'Smart Lock',
              description: 'Access control and entry points',
              selected: selected == 'lock',
              onTap: () => onChanged('lock'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _TypeCard(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Smart Lamp',
              description: 'Ambient lighting and toggles',
              selected: selected == 'lamp',
              onTap: () => onChanged('lamp'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: BorderSide(
          color: selected ? AppColors.primaryLight : AppColors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            color: selected ? AppColors.primary.withValues(alpha: 0.05) : null,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.xl,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryLight.withValues(alpha: 0.15)
                      : AppColors.surfaceContainerDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.lg,
                  color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primaryLight : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepInfo extends StatelessWidget {
  const _StepInfo({
    required this.nameCtl,
    required this.hostCtl,
    required this.portCtl,
    this.onChanged,
  });

  final TextEditingController nameCtl;
  final TextEditingController hostCtl;
  final TextEditingController portCtl;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Device Connection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Enter network coordinates for the device.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            TextFormField(
              controller: nameCtl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onChanged?.call(),
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'e.g. Front Door, Living Room',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: hostCtl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: (_) => onChanged?.call(),
              decoration: const InputDecoration(
                labelText: 'IP Address / Host',
                hintText: 'e.g. 192.168.1.15',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: portCtl,
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged?.call(),
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'e.g. 1212',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepAuth extends StatelessWidget {
  const _StepAuth({
    required this.tokenCtl,
    required this.obscure,
    required this.toggleVisibility,
    this.onChanged,
  });

  final TextEditingController tokenCtl;
  final bool obscure;
  final VoidCallback toggleVisibility;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Security Access',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Enter the secure token configured on your ESP32.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            TextFormField(
              controller: tokenCtl,
              obscureText: obscure,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => onChanged?.call(),
              decoration: InputDecoration(
                labelText: 'Authentication Token',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: toggleVisibility,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTest extends StatefulWidget {
  const _StepTest({
    required this.testing,
    required this.result,
    required this.success,
    required this.onTest,
  });

  final bool testing;
  final String? result;
  final bool success;
  final VoidCallback onTest;

  @override
  State<_StepTest> createState() => _StepTestState();
}

class _StepTestState extends State<_StepTest>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(_StepTest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.testing && !oldWidget.testing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.testing && oldWidget.testing) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test Connection',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Let\'s verify that the app can connect to your device.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.huge),

            // Pulsing connection icon during test
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.testing
                      ? AppColors.primaryLight.withValues(alpha: 0.15)
                      : (widget.result != null
                          ? (widget.success
                              ? Colors.green.withValues(alpha: 0.15)
                              : scheme.error.withValues(alpha: 0.15))
                          : AppColors.surfaceContainerDark),
                  border: Border.all(
                    color: widget.testing
                        ? AppColors.primaryLight
                        : (widget.result != null
                            ? (widget.success ? Colors.green : scheme.error)
                            : AppColors.outline),
                    width: 2,
                  ),
                ),
                child: Icon(
                  widget.testing
                      ? Icons.wifi_find_rounded
                      : (widget.result != null
                          ? (widget.success
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded)
                          : Icons.wifi_rounded),
                  size: AppIconSize.xl,
                  color: widget.testing
                      ? AppColors.primaryLight
                      : (widget.result != null
                          ? (widget.success ? Colors.green : scheme.error)
                          : AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.huge),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.testing ? null : widget.onTest,
                icon: const Icon(Icons.tap_and_play_rounded),
                label: Text(widget.testing ? 'Testing connection...' : 'Test Connection'),
              ),
            ),

            if (widget.result != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: widget.success
                      ? Colors.green.withValues(alpha: 0.1)
                      : scheme.errorContainer,
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(
                    color: widget.success
                        ? Colors.green.withValues(alpha: 0.25)
                        : scheme.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                      color: widget.success ? Colors.green : scheme.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.result!,
                        style: TextStyle(
                          color: widget.success ? Colors.green : scheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepSave extends StatefulWidget {
  const _StepSave({required this.draft, required this.onSave});
  final LockSettings draft;
  final VoidCallback onSave;

  @override
  State<_StepSave> createState() => _StepSaveState();
}

class _StepSaveState extends State<_StepSave>
    with SingleTickerProviderStateMixin {
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.elasticOut,
      ),
    );
    _successController.forward();
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLamp = widget.draft.deviceType == 'lamp';

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: AppIconSize.xl,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'All Set!',
              style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Your new device is ready to be added.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLamp ? Icons.lightbulb_outline_rounded : Icons.lock_outline_rounded,
                        color: AppColors.primaryLight,
                        size: AppIconSize.md,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.draft.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isLamp ? 'Smart Lamp' : 'Smart Lock'} \u00b7 ${widget.draft.host}:${widget.draft.port}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onSave,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save & Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
