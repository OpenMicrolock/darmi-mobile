import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Device {
  const Device({
    this.id = '',
    this.name = '',
    required this.host,
    required this.port,
    required this.token,
    this.type = 'lock',
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
  final String type;
  final String wifiSsid;
  final String wifiPassword;
  final String apSsid;
  final String apPassword;
  final bool apBroadcastSsid;
  final bool hideSsidInApMode;

  bool get isComplete => host.isNotEmpty && token.isNotEmpty && port > 0;
  bool get isLamp => type == 'lamp';

  Device copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? token,
    String? type,
    String? wifiSsid,
    String? wifiPassword,
    String? apSsid,
    String? apPassword,
    bool? apBroadcastSsid,
    bool? hideSsidInApMode,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      type: type ?? this.type,
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
    'type': type,
    'wifiSsid': wifiSsid,
    'wifiPassword': wifiPassword,
    'apSsid': apSsid,
    'apPassword': apPassword,
    'apBroadcastSsid': apBroadcastSsid,
    'hideSsidInApMode': hideSsidInApMode,
  };

  static Device fromJson(Map<String, dynamic> json) {
    return Device(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      host: (json['host'] as String?) ?? '',
      port: (json['port'] as num?)?.toInt() ?? defaultPort,
      token: (json['token'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'lock',
      wifiSsid: (json['wifiSsid'] as String?) ?? '',
      wifiPassword: (json['wifiPassword'] as String?) ?? '',
      apSsid: (json['apSsid'] as String?) ?? '',
      apPassword: (json['apPassword'] as String?) ?? '',
      apBroadcastSsid: (json['apBroadcastSsid'] as bool?) ?? true,
      hideSsidInApMode: (json['hideSsidInApMode'] as bool?) ?? false,
    );
  }
}

class DeviceStore {
  DeviceStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _kDevices = 'lock_devices';
  static const _kActiveDeviceId = 'active_lock_device_id';

  final FlutterSecureStorage _storage;

  Future<Device?> load() async {
    final devices = await loadDevices();
    if (devices.isNotEmpty) {
      final activeId = await _storage.read(key: _kActiveDeviceId);
      return devices.firstWhere(
        (d) => d.id == activeId,
        orElse: () => devices.first,
      );
    }
    return null;
  }

  Future<List<Device>> loadDevices() async {
    final raw = await _storage.read(key: _kDevices);
    if (raw == null || raw.isEmpty) return const [];
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Device.fromJson)
        .where((d) => d.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<Device> save(Device device) async {
    final devices = [...await loadDevices()];
    final saved = device.copyWith(
      id: device.id.isEmpty ? _newId() : device.id,
      name: device.name.trim().isEmpty ? 'Unnamed' : device.name.trim(),
      port: Device.defaultPort,
    );
    final index = devices.indexWhere((d) => d.id == saved.id);
    if (index == -1) {
      devices.add(saved);
    } else {
      devices[index] = saved;
    }
    await _writeDevices(devices, saved.id);
    return saved;
  }

  Future<Device?> setActive(String id) async {
    final devices = await loadDevices();
    final index = devices.indexWhere((d) => d.id == id);
    if (index == -1) return null;
    final active = devices[index];
    await _storage.write(key: _kActiveDeviceId, value: active.id);
    return active;
  }

  Future<Device?> delete(String id) async {
    final devices = [...await loadDevices()];
    devices.removeWhere((d) => d.id == id);
    if (devices.isEmpty) {
      await clear();
      return null;
    }
    final activeId = await _storage.read(key: _kActiveDeviceId);
    final active = devices.firstWhere(
      (d) => d.id == activeId,
      orElse: () => devices.first,
    );
    await _writeDevices(devices, active.id);
    return active;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kDevices);
    await _storage.delete(key: _kActiveDeviceId);
  }

  Future<void> _writeDevices(List<Device> devices, String activeId) async {
    await _storage.write(
      key: _kDevices,
      value: jsonEncode(devices.map((d) => d.toJson()).toList()),
    );
    await _storage.write(key: _kActiveDeviceId, value: activeId);
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
