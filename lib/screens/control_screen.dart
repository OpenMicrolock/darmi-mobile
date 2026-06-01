import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/lock_api.dart';
import '../settings/settings_store.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/slide_to_action.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({
    super.key,
    required this.store,
    required this.settings,
    required this.onSwitchDevice,
  });

  final SettingsStore store;
  final LockSettings settings;
  final ValueChanged<LockSettings> onSwitchDevice;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late LockApi _api;
  String _stateLabel = '';
  String _connectionStatus = 'unknown';
  bool _busy = false;
  String? _error;
  DateTime? _lastUpdated;

  Timer? _autoLockTimer;
  int _countdownRemaining = 0;

  bool get _isLamp => widget.settings.deviceType == 'lamp';
  bool get _isActive => _stateLabel == 'on' || _stateLabel == 'unlocked';

  String get _stateText {
    if (_stateLabel.isEmpty) return '--';
    if (_isLamp) return _stateLabel == 'on' ? 'ON' : 'OFF';
    return _stateLabel == 'locked' ? 'LOCKED' : 'UNLOCKED';
  }

  LockApi _buildApi() => LockApi(
        host: widget.settings.host,
        port: widget.settings.port,
        token: widget.settings.token,
        deviceType: _isLamp ? DeviceType.lamp : DeviceType.lock,
      );

  @override
  void initState() {
    super.initState();
    _api = _buildApi();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  @override
  void didUpdateWidget(ControlScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings.id != oldWidget.settings.id ||
        widget.settings.host != oldWidget.settings.host ||
        widget.settings.port != oldWidget.settings.port ||
        widget.settings.token != oldWidget.settings.token ||
        widget.settings.deviceType != oldWidget.settings.deviceType) {
      _cancelAutoLock();
      _api.dispose();
      setState(() {
        _api = _buildApi();
        _stateLabel = '';
        _connectionStatus = 'unknown';
        _error = null;
        _lastUpdated = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    }
  }

  @override
  void dispose() {
    _cancelAutoLock();
    _api.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isLamp) {
        final s = await _api.lampStatus();
        _stateLabel = s == DeviceLampState.on ? 'on' : 'off';
      } else {
        final s = await _api.status();
        _stateLabel = s == DeviceLockState.locked ? 'locked' : 'unlocked';
      }
      _connectionStatus = 'active';
      _lastUpdated = DateTime.now();
    } on UnauthorizedException {
      _error = 'Wrong token';
      _connectionStatus = 'error';
    } on LockApiException catch (e) {
      _error = e.message;
      _connectionStatus = 'inactive';
    } catch (e) {
      _error = 'Connection failed';
      _connectionStatus = 'inactive';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _performAction(bool targetActive) async {
    if (_busy || _stateLabel.isEmpty) return;
    
    // Provide haptic feedback for user interaction
    HapticFeedback.mediumImpact();
    
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isLamp) {
        final s = targetActive ? await _api.turnOn() : await _api.turnOff();
        _stateLabel = s == DeviceLampState.on ? 'on' : 'off';
        _cancelAutoLock();
      } else {
        final s = targetActive ? await _api.unlock() : await _api.lock();
        _stateLabel = s == DeviceLockState.locked ? 'locked' : 'unlocked';
        
        if (_isActive) {
          // If unlocked, start auto-lock countdown timer
          _startAutoLock();
        } else {
          _cancelAutoLock();
        }
      }
      _connectionStatus = 'active';
      _lastUpdated = DateTime.now();
      HapticFeedback.lightImpact();
    } on UnauthorizedException {
      _error = 'Wrong auth token';
      _connectionStatus = 'error';
    } on LockApiException catch (e) {
      _error = e.message;
      _connectionStatus = 'inactive';
    } catch (e) {
      _error = 'Action failed: connection issue';
      _connectionStatus = 'inactive';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startAutoLock() {
    _cancelAutoLock();
    _countdownRemaining = 5;
    if (mounted) setState(() {});
    
    _autoLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownRemaining--;
        if (_countdownRemaining <= 0) {
          timer.cancel();
          _autoLock();
        }
      });
    });
  }

  void _cancelAutoLock() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
    setState(() {
      _countdownRemaining = 0;
    });
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
      _connectionStatus = 'active';
      _lastUpdated = DateTime.now();
      HapticFeedback.lightImpact();
    } on UnauthorizedException {
      _error = 'Wrong auth token';
      _connectionStatus = 'error';
    } on LockApiException catch (e) {
      _error = e.message;
      _connectionStatus = 'inactive';
    } catch (e) {
      _error = 'Auto-lock connection failed';
      _connectionStatus = 'inactive';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatTime(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lastUpdatedStr = _lastUpdated != null ? _formatTime(_lastUpdated!) : null;

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: AppSpacing.screenPadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Hero card displaying status
          HeroStatusCard(
            isLamp: _isLamp,
            stateText: _stateText,
            isActive: _isActive,
            deviceName: widget.settings.name,
            connectionStatus: _connectionStatus,
            busy: _busy,
            lastUpdated: lastUpdatedStr,
            countdownRemaining: _countdownRemaining,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Error banner
          if (_error != null) ...[
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: scheme.onErrorContainer, size: AppIconSize.md),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Primary control actions
          if (_stateLabel.isNotEmpty) ...[
            if (_isLamp)
              // Lamp toggle switch button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _performAction(!_isActive),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isActive ? AppColors.outline : AppColors.amber,
                    foregroundColor: _isActive ? AppColors.textPrimary : Colors.black,
                  ),
                  icon: Icon(_isActive ? Icons.power_settings_new_rounded : Icons.power_settings_new_rounded),
                  label: Text(_isActive ? 'TURN OFF' : 'TURN ON'),
                ),
              )
            else if (!_isActive)
              // Locked: slide-to-unlock gesture
              SlideToAction(
                onCompleted: () => _performAction(true),
                text: 'Swipe right to unlock',
                completedText: 'Unlocking door...',
                color: AppColors.unlocked,
              ),
            // when unlocked, no action button shown (auto-lock handles it)
            const SizedBox(height: AppSpacing.lg),
          ],

          // Refresh action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh Status'),
            ),
          ),
        ],
      ),
    );
  }
}
