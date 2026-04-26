import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:microlock/api/lock_api.dart';

void main() {
  group('LockApi config', () {
    test('getConfig returns hide_ssid_in_ap_mode', () async {
      final api = LockApi(
        host: '127.0.0.1',
        port: 1212,
        token: 'demo-token',
        client: MockClient((request) async {
          expect(request.url.path, '/config/status');
          expect(request.method, 'POST');
          return http.Response(
            jsonEncode({'hide_ssid_in_ap_mode': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final config = await api.getConfig();

      expect(config.hideSsidInApMode, isTrue);
      api.dispose();
    });

    test(
      'updateConfig sends hide_ssid_in_ap_mode and parses response',
      () async {
        final api = LockApi(
          host: '127.0.0.1',
          port: 1212,
          token: 'demo-token',
          client: MockClient((request) async {
            expect(request.url.path, '/config');
            expect(request.method, 'POST');

            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['token'], 'demo-token');
            expect(body['hide_ssid_in_ap_mode'], isTrue);

            return http.Response(
              jsonEncode({'hide_ssid_in_ap_mode': true, 'message': 'saved'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        final config = await api.updateConfig(hideSsidInApMode: true);

        expect(config.hideSsidInApMode, isTrue);
        api.dispose();
      },
    );
  });
}
