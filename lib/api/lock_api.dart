import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

enum DeviceLockState { locked, unlocked }

class ProvisioningConfig {
  const ProvisioningConfig({
    required this.wifiSsid,
    required this.wifiConfigured,
    required this.wifiHasPassword,
    required this.apSsid,
    required this.apBroadcastSsid,
    required this.apHasPassword,
    this.mode,
    this.ip,
    this.name,
  });

  final String wifiSsid;
  final bool wifiConfigured;
  final bool wifiHasPassword;
  final String apSsid;
  final bool apBroadcastSsid;
  final bool apHasPassword;
  final String? mode;
  final String? ip;
  final String? name;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
  @override
  String toString() => 'Unauthorized: wrong token';
}

class LockApiException implements Exception {
  LockApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LockApi {
  LockApi({
    required this.host,
    required this.port,
    required this.token,
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final String host;
  final int port;
  final String token;
  final http.Client _client;
  final Duration _timeout;

  Uri _uri(String path) => Uri.parse('http://$host:$port$path');

  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String get _body => jsonEncode({'token': token});

  Future<Map<String, dynamic>> ping() async {
    final res = await _send(() => _client.get(_uri('/')));
    return _decode(res);
  }

  Future<DeviceLockState> lock() => _action('/lock');
  Future<DeviceLockState> unlock() => _action('/unlock');
  Future<DeviceLockState> status() => _action('/status');

  Future<ProvisioningConfig> getProvisioningConfig() async {
    final res = await _send(() => _client.get(_uri('/config'), headers: _headers));
    return _decodeProvisioningConfig(res);
  }

  Future<ProvisioningConfig> updateProvisioningConfig({
    required String wifiSsid,
    required String wifiPassword,
    required String apSsid,
    required String apPassword,
    required bool apBroadcastSsid,
  }) async {
    final res = await _send(
      () => _client.post(
        _uri('/config'),
        headers: _headers,
        body: jsonEncode({
          'wifi_ssid': wifiSsid,
          'wifi_password': wifiPassword,
          'ap_ssid': apSsid,
          'ap_password': apPassword,
          'ap_broadcast_ssid': apBroadcastSsid,
        }),
      ),
    );
    return _decodeProvisioningConfig(res);
  }

  Future<DeviceLockState> _action(String path) async {
    final res = await _send(
      () => _client.post(_uri(path), headers: _headers, body: _body),
    );
    final data = _decode(res);
    final state = data['state'];
    if (state == 'locked') return DeviceLockState.locked;
    if (state == 'unlocked') return DeviceLockState.unlocked;
    throw LockApiException('Unexpected state: $state');
  }

  Future<http.Response> _send(Future<http.Response> Function() req) async {
    try {
      final res = await req().timeout(_timeout);
      if (res.statusCode == 401) throw const UnauthorizedException();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw LockApiException(_describeError(res));
      }
      return res;
    } on TimeoutException {
      throw LockApiException('Timeout — device did not respond');
    } on SocketException catch (e) {
      throw LockApiException('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw LockApiException('HTTP error: ${e.message}');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw LockApiException('Invalid response body');
    }
  }

  ProvisioningConfig _decodeProvisioningConfig(http.Response res) {
    final data = _decode(res);
    final wifi = data['wifi'];
    final ap = data['ap'];
    if (wifi is! Map<String, dynamic> || ap is! Map<String, dynamic>) {
      throw LockApiException('Unexpected config response');
    }

    final wifiSsid = wifi['ssid'];
    final wifiConfigured = wifi['configured'];
    final wifiHasPassword = wifi['has_password'];
    final apSsid = ap['ssid'];
    final apBroadcastSsid = ap['broadcast_ssid'];
    final apHasPassword = ap['has_password'];

    if (wifiSsid is! String ||
        wifiConfigured is! bool ||
        wifiHasPassword is! bool ||
        apSsid is! String ||
        apBroadcastSsid is! bool ||
        apHasPassword is! bool) {
      throw LockApiException('Unexpected config response');
    }

    return ProvisioningConfig(
      wifiSsid: wifiSsid,
      wifiConfigured: wifiConfigured,
      wifiHasPassword: wifiHasPassword,
      apSsid: apSsid,
      apBroadcastSsid: apBroadcastSsid,
      apHasPassword: apHasPassword,
      mode: data['mode'] as String?,
      ip: data['ip'] as String?,
      name: data['name'] as String?,
    );
  }

  String _describeError(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final reason = data['reason'];
      final error = data['error'];
      if (reason is String && error is String) {
        return '$error: $reason';
      }
      if (reason is String) {
        return reason;
      }
      if (error is String) {
        return error;
      }
    } catch (_) {
      // Fall back to status-only error.
    }

    return 'HTTP ${res.statusCode}';
  }

  void dispose() => _client.close();
}
