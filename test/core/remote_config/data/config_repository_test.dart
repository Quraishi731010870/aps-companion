import 'dart:convert';

import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/core/remote_config/data/config_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cacheKey = 'afghanpay_mobile_config_v1';

final _payload = {
  'version': 4,
  'updatedAt': '2026-10-28T11:10:07Z',
  'configuration': {
    'mobile.application': {
      'maintenanceMode': true,
      'maintenanceMessage': 'Back at 14:00',
    },
    'mobile.limits': {'maxAmount': 50000},
  },
  'features': [
    {'key': 'card_to_card', 'enabled': false},
    {'key': 'purchase', 'enabled': true},
  ],
  'content': [
    {'key': 'home.banner', 'locale': 'en'},
  ],
};

ConfigRepository _repository(http.Response Function() reply) =>
    ConfigRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        client: MockClient((_) async => reply()),
      ),
    );

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('parses and merges a live configuration', () async {
    final config = await _repository(
      () => http.Response(jsonEncode(_payload), 200),
    ).load();

    expect(config.fromCache, isFalse);
    expect(config.version, 4);
    expect(config.maintenanceMode, isTrue);
    expect(config.maintenanceMessage, 'Back at 14:00');
    expect(config.values['maxAmount'], 50000);
    expect(config.featureEnabled('card_to_card', safeDefault: true), isFalse);
    expect(config.featureEnabled('purchase'), isTrue);
    expect(config.featureEnabled('unknown', safeDefault: true), isTrue);
    expect(config.content, hasLength(1));
  });

  test('caches the live configuration for offline use', () async {
    await _repository(() => http.Response(jsonEncode(_payload), 200)).load();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_cacheKey), isNotNull);
  });

  test('falls back to the cached copy when offline', () async {
    SharedPreferences.setMockInitialValues({_cacheKey: jsonEncode(_payload)});

    final config = await _repository(
      () => throw http.ClientException('offline'),
    ).load();

    expect(config.fromCache, isTrue);
    expect(config.version, 4);
  });

  test(
    'returns the empty configuration with no network and no cache',
    () async {
      final config = await _repository(() => http.Response('', 503)).load();

      expect(config, same(MobileConfiguration.empty));
      expect(config.maintenanceMode, isFalse);
    },
  );

  test('a non-string maintenance message is ignored', () {
    const config = MobileConfiguration(
      version: 1,
      updatedAt: null,
      values: {'maintenanceMessage': 42},
      features: {},
      content: [],
      fromCache: false,
    );
    expect(config.maintenanceMessage, isNull);
  });
}
