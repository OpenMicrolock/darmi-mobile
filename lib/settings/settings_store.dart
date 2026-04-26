import 'package:shared_preferences/shared_preferences.dart';

class LockSettings {
  const LockSettings({
    required this.host,
    required this.port,
    required this.token,
    this.hideSsidInApMode = false,
  });

  final String host;
  final int port;
  final String token;
  final bool hideSsidInApMode;

  bool get isComplete => host.isNotEmpty && token.isNotEmpty && port > 0;

  LockSettings copyWith({
    String? host,
    int? port,
    String? token,
    bool? hideSsidInApMode,
  }) {
    return LockSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      hideSsidInApMode: hideSsidInApMode ?? this.hideSsidInApMode,
    );
  }
}

class SettingsStore {
  SettingsStore([SharedPreferences? prefs]) : _prefs = prefs;

  static const _kHost = 'lock_host';
  static const _kPort = 'lock_port';
  static const _kToken = 'lock_token';
  static const _kHideSsidInApMode = 'lock_hide_ssid_in_ap_mode';

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
      hideSsidInApMode: prefs.getBool(_kHideSsidInApMode) ?? false,
    );
  }

  Future<void> save(LockSettings settings) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_kHost, settings.host);
    await prefs.setString(_kPort, settings.port.toString());
    await prefs.setString(_kToken, settings.token);
    await prefs.setBool(_kHideSsidInApMode, settings.hideSsidInApMode);
  }

  Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_kHost);
    await prefs.remove(_kPort);
    await prefs.remove(_kToken);
    await prefs.remove(_kHideSsidInApMode);
  }
}
