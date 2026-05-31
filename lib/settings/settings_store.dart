import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LockSettings {
  const LockSettings({
    this.id = '',
    this.name = 'Default device',
    required this.host,
    required this.port,
    required this.token,
    this.deviceType = 'lock',
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.apSsid = '',
    this.apPassword = '',
    this.apBroadcastSsid = true,
    this.hideSsidInApMode = false,
  });

  static const int defaultPort = 1212;

  final String id;
  final String name;
  final String host;
  final int port;
  final String token;
  final String deviceType;
  final String wifiSsid;
  final String wifiPassword;
  final String apSsid;
  final String apPassword;
  final bool apBroadcastSsid;
  final bool hideSsidInApMode;

  bool get isComplete => host.isNotEmpty && token.isNotEmpty && port > 0;

  LockSettings copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? token,
    String? deviceType,
    String? wifiSsid,
    String? wifiPassword,
    String? apSsid,
    String? apPassword,
    bool? apBroadcastSsid,
    bool? hideSsidInApMode,
  }) {
    return LockSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      deviceType: deviceType ?? this.deviceType,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      apSsid: apSsid ?? this.apSsid,
      apPassword: apPassword ?? this.apPassword,
      apBroadcastSsid: apBroadcastSsid ?? this.apBroadcastSsid,
      hideSsidInApMode: hideSsidInApMode ?? this.hideSsidInApMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'token': token,
    'deviceType': deviceType,
    'wifiSsid': wifiSsid,
    'wifiPassword': wifiPassword,
    'apSsid': apSsid,
    'apPassword': apPassword,
    'apBroadcastSsid': apBroadcastSsid,
    'hideSsidInApMode': hideSsidInApMode,
  };

  static LockSettings fromJson(Map<String, dynamic> json) {
    return LockSettings(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Default device',
      host: (json['host'] as String?) ?? '',
      port: (json['port'] as num?)?.toInt() ?? defaultPort,
      token: (json['token'] as String?) ?? '',
      deviceType: (json['deviceType'] as String?) ?? 'lock',
      wifiSsid: (json['wifiSsid'] as String?) ?? '',
      wifiPassword: (json['wifiPassword'] as String?) ?? '',
      apSsid: (json['apSsid'] as String?) ?? '',
      apPassword: (json['apPassword'] as String?) ?? '',
      apBroadcastSsid: (json['apBroadcastSsid'] as bool?) ?? true,
      hideSsidInApMode: (json['hideSsidInApMode'] as bool?) ?? false,
    );
  }
}

class SettingsStore {
  SettingsStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _kHost = 'lock_host';
  static const _kPort = 'lock_port';
  static const _kToken = 'lock_token';
  static const _kDevices = 'lock_devices';
  static const _kActiveDeviceId = 'active_lock_device_id';

  final FlutterSecureStorage _storage;

  Future<LockSettings?> load() async {
    final devices = await loadDevices();
    if (devices.isNotEmpty) {
      final activeId = await _storage.read(key: _kActiveDeviceId);
      return devices.firstWhere(
        (device) => device.id == activeId,
        orElse: () => devices.first,
      );
    }

    final host = await _storage.read(key: _kHost);
    final port = await _storage.read(key: _kPort);
    final token = await _storage.read(key: _kToken);
    if (host == null || token == null) return null;
    final migrated = LockSettings(
      id: _newId(),
      name: 'Default device',
      host: host,
      port: int.tryParse(port ?? '') ?? LockSettings.defaultPort,
      token: token,
    );
    await _writeDevices([migrated], migrated.id);
    return migrated;
  }

  Future<List<LockSettings>> loadDevices() async {
    final raw = await _storage.read(key: _kDevices);
    if (raw == null || raw.isEmpty) return const [];
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LockSettings.fromJson)
        .where((device) => device.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<LockSettings> save(LockSettings settings) async {
    final devices = [...await loadDevices()];
    final saved = settings.copyWith(
      id: settings.id.isEmpty ? _newId() : settings.id,
      name: settings.name.trim().isEmpty
          ? 'Unnamed device'
          : settings.name.trim(),
    );
    final index = devices.indexWhere((device) => device.id == saved.id);
    if (index == -1) {
      devices.add(saved);
    } else {
      devices[index] = saved;
    }

    await _writeDevices(devices, saved.id);
    await _storage.write(key: _kHost, value: saved.host);
    await _storage.write(key: _kPort, value: saved.port.toString());
    await _storage.write(key: _kToken, value: saved.token);
    return saved;
  }

  Future<LockSettings?> setActiveDevice(String id) async {
    final devices = await loadDevices();
    final index = devices.indexWhere((device) => device.id == id);
    if (index == -1) return null;
    final active = devices[index];
    await _storage.write(key: _kActiveDeviceId, value: active.id);
    await _storage.write(key: _kHost, value: active.host);
    await _storage.write(key: _kPort, value: active.port.toString());
    await _storage.write(key: _kToken, value: active.token);
    return active;
  }

  Future<LockSettings?> deleteDevice(String id) async {
    final devices = [...await loadDevices()];
    devices.removeWhere((device) => device.id == id);

    if (devices.isEmpty) {
      await clear();
      return null;
    }

    final activeId = await _storage.read(key: _kActiveDeviceId);
    final active = devices.firstWhere(
      (device) => device.id == activeId,
      orElse: () => devices.first,
    );
    await _writeDevices(devices, active.id);
    await _storage.write(key: _kHost, value: active.host);
    await _storage.write(key: _kPort, value: active.port.toString());
    await _storage.write(key: _kToken, value: active.token);
    return active;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kDevices);
    await _storage.delete(key: _kActiveDeviceId);
    await _storage.delete(key: _kHost);
    await _storage.delete(key: _kPort);
    await _storage.delete(key: _kToken);
  }

  Future<void> _writeDevices(
    List<LockSettings> devices,
    String activeId,
  ) async {
    await _storage.write(
      key: _kDevices,
      value: jsonEncode(devices.map((device) => device.toJson()).toList()),
    );
    await _storage.write(key: _kActiveDeviceId, value: activeId);
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
