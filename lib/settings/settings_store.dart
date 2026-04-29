import 'package:shared_preferences/shared_preferences.dart';

class LockSettings {
  const LockSettings({
    required this.host,
    required this.port,
    required this.token,
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.apSsid = '',
    this.apPassword = '',
    this.apBroadcastSsid = true,
    this.hideSsidInApMode = false,
  });

  static const defaultHost = '';
  static const defaultPort = 1212;

  final String host;
  final int port;
  final String token;
  final String wifiSsid;
  final String wifiPassword;
  final String apSsid;
  final String apPassword;
  final bool apBroadcastSsid;
  final bool hideSsidInApMode;

  bool get isComplete => host.isNotEmpty && token.isNotEmpty && port > 0;

  LockSettings copyWith({
    String? host,
    int? port,
    String? token,
    String? wifiSsid,
    String? wifiPassword,
    String? apSsid,
    String? apPassword,
    bool? apBroadcastSsid,
    bool? hideSsidInApMode,
  }) {
    return LockSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      apSsid: apSsid ?? this.apSsid,
      apPassword: apPassword ?? this.apPassword,
      apBroadcastSsid: apBroadcastSsid ?? this.apBroadcastSsid,
      hideSsidInApMode: hideSsidInApMode ?? this.hideSsidInApMode,
    );
  }
}

class SettingsStore {
  SettingsStore([SharedPreferences? prefs]) : _prefs = prefs;

  static const _kHost = 'lock_host';
  static const _kPort = 'lock_port';
  static const _kToken = 'lock_token';
  static const _kWifiSsid = 'lock_wifi_ssid';
  static const _kWifiPassword = 'lock_wifi_password';
  static const _kApSsid = 'lock_ap_ssid';
  static const _kApPassword = 'lock_ap_password';
  static const _kApBroadcastSsid = 'lock_ap_broadcast_ssid';
  static const _kHideSsidInApMode = 'lock_hide_ssid_in_ap_mode';

  final SharedPreferences? _prefs;

  Future<LockSettings?> load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final hasAnySettings =
        prefs.containsKey(_kHost) ||
        prefs.containsKey(_kToken) ||
        prefs.containsKey(_kWifiSsid) ||
        prefs.containsKey(_kApSsid) ||
        prefs.containsKey(_kApPassword) ||
        prefs.containsKey(_kApBroadcastSsid) ||
        prefs.containsKey(_kHideSsidInApMode);
    if (!hasAnySettings) return null;

    final host = prefs.getString(_kHost) ?? LockSettings.defaultHost;
    final port = prefs.getString(_kPort);
    final token = prefs.getString(_kToken) ?? '';
    final legacyHideSsidInApMode = prefs.getBool(_kHideSsidInApMode) ?? false;
    final hideSsidInApMode = prefs.getBool(_kHideSsidInApMode) ?? false;

    return LockSettings(
      host: host,
      port: int.tryParse(port ?? '') ?? LockSettings.defaultPort,
      token: token,
      wifiSsid: prefs.getString(_kWifiSsid) ?? '',
      wifiPassword: prefs.getString(_kWifiPassword) ?? '',
      apSsid: prefs.getString(_kApSsid) ?? '',
      apPassword: prefs.getString(_kApPassword) ?? '',
      apBroadcastSsid:
          prefs.getBool(_kApBroadcastSsid) ?? !legacyHideSsidInApMode,
      hideSsidInApMode: hideSsidInApMode,
    );
  }

  Future<void> save(LockSettings settings) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_kHost, settings.host);
    await prefs.setString(_kPort, settings.port.toString());
    await prefs.setString(_kToken, settings.token);
    await prefs.setString(_kWifiSsid, settings.wifiSsid);
    await prefs.setString(_kWifiPassword, settings.wifiPassword);
    await prefs.setString(_kApSsid, settings.apSsid);
    await prefs.setString(_kApPassword, settings.apPassword);
    await prefs.setBool(_kApBroadcastSsid, settings.apBroadcastSsid);
    await prefs.setBool(_kHideSsidInApMode, settings.hideSsidInApMode);
  }

  Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_kHost);
    await prefs.remove(_kPort);
    await prefs.remove(_kToken);
    await prefs.remove(_kWifiSsid);
    await prefs.remove(_kWifiPassword);
    await prefs.remove(_kApSsid);
    await prefs.remove(_kApPassword);
    await prefs.remove(_kApBroadcastSsid);
    await prefs.remove(_kHideSsidInApMode);
  }
}
