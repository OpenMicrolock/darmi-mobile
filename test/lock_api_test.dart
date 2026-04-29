import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:microlock/api/lock_api.dart';

void main() {
  group('LockApi provisioning', () {
    test('getProvisioningConfig reads dynamic Wi-Fi and AP config', () async {
      final api = LockApi(
        host: '127.0.0.1',
        port: 1212,
        token: 'demo-token',
        client: MockClient((request) async {
          expect(request.url.path, '/config');
          expect(request.method, 'GET');
          return http.Response(
            jsonEncode({
              'name': 'microlock-simulator',
              'mode': 'ap',
              'ip': '192.168.4.1',
              'wifi': {
                'ssid': '',
                'configured': false,
                'has_password': false,
              },
              'ap': {
                'ssid': 'Device-Setup',
                'broadcast_ssid': true,
                'has_password': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final config = await api.getProvisioningConfig();

      expect(config.wifiConfigured, isFalse);
      expect(config.apSsid, 'Device-Setup');
      expect(config.apBroadcastSsid, isTrue);
      api.dispose();
    });

    test(
      'updateProvisioningConfig sends Wi-Fi and AP settings',
      () async {
        final api = LockApi(
          host: '127.0.0.1',
          port: 1212,
          token: 'demo-token',
          client: MockClient((request) async {
            expect(request.url.path, '/config');
            expect(request.method, 'POST');

            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['wifi_ssid'], 'OfficeWiFi');
            expect(body['wifi_password'], 'office-secret');
            expect(body['ap_ssid'], 'Device-Setup');
            expect(body['ap_password'], 'device-pass');
            expect(body['ap_broadcast_ssid'], isFalse);

            return http.Response(
              jsonEncode({
                'saved': true,
                'reconfigure_pending': true,
                'requested_mode': 'sta',
                'wifi': {
                  'ssid': 'OfficeWiFi',
                  'configured': true,
                  'has_password': true,
                },
                'ap': {
                  'ssid': 'Device-Setup',
                  'broadcast_ssid': false,
                  'has_password': true,
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        final config = await api.updateProvisioningConfig(
          wifiSsid: 'OfficeWiFi',
          wifiPassword: 'office-secret',
          apSsid: 'Device-Setup',
          apPassword: 'device-pass',
          apBroadcastSsid: false,
        );

        expect(config.wifiSsid, 'OfficeWiFi');
        expect(config.apBroadcastSsid, isFalse);
        api.dispose();
      },
    );
  });
}
