import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LockSettings {
  const LockSettings({required this.host, required this.port, required this.token});

  final String host;
  final int port;
  final String token;

  bool get isComplete => host.isNotEmpty && token.isNotEmpty && port > 0;
}

class SettingsStore {
  SettingsStore([FlutterSecureStorage? storage])
    : _storage = storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _kHost = 'lock_host';
  static const _kPort = 'lock_port';
  static const _kToken = 'lock_token';

  final FlutterSecureStorage _storage;

  Future<LockSettings?> load() async {
    final host = await _storage.read(key: _kHost);
    final port = await _storage.read(key: _kPort);
    final token = await _storage.read(key: _kToken);
    if (host == null || token == null) return null;
    return LockSettings(
      host: host,
      port: int.tryParse(port ?? '') ?? 1212,
      token: token,
    );
  }

  Future<void> save(LockSettings settings) async {
    await _storage.write(key: _kHost, value: settings.host);
    await _storage.write(key: _kPort, value: settings.port.toString());
    await _storage.write(key: _kToken, value: settings.token);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kHost);
    await _storage.delete(key: _kPort);
    await _storage.delete(key: _kToken);
  }
}
