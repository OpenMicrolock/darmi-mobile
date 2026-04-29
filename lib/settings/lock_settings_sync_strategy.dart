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
