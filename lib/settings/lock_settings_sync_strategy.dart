import '../api/lock_api.dart';
import 'settings_store.dart';

class LockSettingsSyncException implements Exception {
  const LockSettingsSyncException(this.message);

  final String message;
}

abstract class LockSettingsSyncStrategy {
  Future<LockSettings> load(LockSettings settings);
  Future<LockSettings> save(LockSettings settings);
}

class LockSettingsSyncStrategyFactory {
  const LockSettingsSyncStrategyFactory();

  LockSettingsSyncStrategy create(LockSettings? settings) {
    if (settings != null && settings.isComplete) {
      return const RemoteLockSettingsSyncStrategy();
    }
    return const LocalOnlyLockSettingsSyncStrategy();
  }
}

class LocalOnlyLockSettingsSyncStrategy implements LockSettingsSyncStrategy {
  const LocalOnlyLockSettingsSyncStrategy();

  @override
  Future<LockSettings> load(LockSettings settings) async => settings;

  @override
  Future<LockSettings> save(LockSettings settings) async => settings;
}

class RemoteLockSettingsSyncStrategy implements LockSettingsSyncStrategy {
  const RemoteLockSettingsSyncStrategy();

  @override
  Future<LockSettings> load(LockSettings settings) async {
    final api = _buildApi(settings);
    try {
      final config = await api.getConfig();
      return settings.copyWith(hideSsidInApMode: config.hideSsidInApMode);
    } on UnauthorizedException {
      throw const LockSettingsSyncException(
        'Invalid token. Could not load lock settings from device.',
      );
    } on LockApiException catch (e) {
      throw LockSettingsSyncException(
        'Could not load lock settings from device: ${e.message}',
      );
    } finally {
      api.dispose();
    }
  }

  @override
  Future<LockSettings> save(LockSettings settings) async {
    final api = _buildApi(settings);
    try {
      final config = await api.updateConfig(
        hideSsidInApMode: settings.hideSsidInApMode,
      );
      return settings.copyWith(hideSsidInApMode: config.hideSsidInApMode);
    } on UnauthorizedException {
      throw const LockSettingsSyncException(
        'Invalid token. Check your device settings.',
      );
    } on LockApiException catch (e) {
      throw LockSettingsSyncException(
        'Could not update lock settings on device: ${e.message}',
      );
    } finally {
      api.dispose();
    }
  }

  LockApi _buildApi(LockSettings settings) {
    return LockApi(
      host: settings.host,
      port: settings.port,
      token: settings.token,
    );
  }
}
