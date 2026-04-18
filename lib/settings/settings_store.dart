import 'package:shared_preferences/shared_preferences.dart';

class LockSettings {
  const LockSettings({required this.host, required this.port, required this.token});

  final String host;
  final int port;
  final String token;

  bool get isComplete => host.isNotEmpty && token.isNotEmpty && port > 0;
}

class SettingsStore {
  SettingsStore([SharedPreferences? prefs]) : _prefs = prefs;

  static const _kHost = 'lock_host';
  static const _kPort = 'lock_port';
  static const _kToken = 'lock_token';

  final SharedPreferences? _prefs;

  Future<LockSettings?> load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final host = prefs.getString(_kHost);
    final port = prefs.getString(_kPort);
    final token = prefs.getString(_kToken);
    if (host == null || token == null) return null;
    return LockSettings(
      host: host,
      port: int.tryParse(port ?? '') ?? 1212,
      token: token,
    );
  }

  Future<void> save(LockSettings settings) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_kHost, settings.host);
    await prefs.setString(_kPort, settings.port.toString());
    await prefs.setString(_kToken, settings.token);
  }

  Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_kHost);
    await prefs.remove(_kPort);
    await prefs.remove(_kToken);
  }
}