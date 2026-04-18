import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

enum DeviceLockState { locked, unlocked }

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
        throw LockApiException('HTTP ${res.statusCode}');
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

  void dispose() => _client.close();
}
