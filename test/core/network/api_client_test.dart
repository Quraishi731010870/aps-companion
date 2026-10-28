import 'dart:convert';

import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_app.dart';

const _base = 'http://api.test';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  const storage = FlutterSecureStorage();

  setUp(
    () => mockSecureStorage(
      values: {
        SecureKey.accessToken: 'old-access',
        SecureKey.refreshToken: 'old-refresh',
        SecureKey.userProfile: '{"id":"user-1","displayName":"Demo"}',
      },
    ),
  );

  test('sends the stored bearer token and decodes the body', () async {
    late http.Request sent;
    final api = ApiClient(
      baseUrl: _base,
      client: MockClient((request) async {
        sent = request;
        return _json({'ok': true});
      }),
    );

    final json = await api.getJson('/api/v1/me', etag: 'v7');

    expect(json, {'ok': true});
    expect(sent.url.toString(), '$_base/api/v1/me');
    expect(sent.headers['Authorization'], 'Bearer old-access');
    expect(sent.headers['If-None-Match'], 'v7');
  });

  test('unauthenticated calls omit the Authorization header', () async {
    late http.Request sent;
    final api = ApiClient(
      baseUrl: _base,
      client: MockClient((request) async {
        sent = request;
        return _json({});
      }),
    );

    await api.getJson('/public', authenticated: false);

    expect(sent.headers.containsKey('Authorization'), isFalse);
  });

  test('server errors become a generic ApiException', () async {
    final api = ApiClient(
      baseUrl: _base,
      client: MockClient((_) async => http.Response('secret stack trace', 500)),
    );

    final error = await api
        .getJson('/boom')
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<ApiException>());
    expect((error! as ApiException).statusCode, 500);
    expect(error.toString(), isNot(contains('secret')));
  });

  test('a 401 refreshes the tokens once and retries', () async {
    final authHeaders = <String?>[];
    final api = ApiClient(
      baseUrl: _base,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          expect(jsonDecode(request.body), {'refreshToken': 'old-refresh'});
          return _json({'accessToken': 'new-access', 'refreshToken': 'new-r'});
        }
        authHeaders.add(request.headers['Authorization']);
        return authHeaders.length == 1
            ? http.Response('', 401)
            : _json({'retried': true});
      }),
    );

    final json = await api.postJson('/api/v1/transactions', {'a': 1});

    expect(json, {'retried': true});
    expect(authHeaders, ['Bearer old-access', 'Bearer new-access']);
    expect(await storage.read(key: 'afghanpay_refresh_token'), 'new-r');
  });

  test('a rejected refresh clears the whole stored session', () async {
    final api = ApiClient(
      baseUrl: _base,
      client: MockClient((request) async => http.Response('', 401)),
    );

    await expectLater(api.getJson('/private'), throwsA(isA<ApiException>()));

    expect(await api.hasAccessToken(), isFalse);
    expect(await storage.read(key: 'afghanpay_refresh_token'), isNull);
    // The stored user goes with the session.
    expect(await storage.read(key: SecureKey.userProfile.storageKey), isNull);
  });

  test('parallel 401s share a single refresh call', () async {
    var refreshes = 0;
    final api = ApiClient(
      baseUrl: _base,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _json({'accessToken': 'new-access', 'refreshToken': 'new-r'});
        }
        return request.headers['Authorization'] == 'Bearer new-access'
            ? _json({})
            : http.Response('', 401);
      }),
    );

    await Future.wait([api.getJson('/a'), api.getJson('/b')]);

    expect(refreshes, 1);
  });
}
