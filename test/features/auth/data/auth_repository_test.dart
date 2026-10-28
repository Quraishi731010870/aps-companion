import 'dart:convert';

import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  AuthRepository repository(http.Response Function(http.Request) reply) =>
      AuthRepository(
        ApiClient(
          baseUrl: 'http://api.test',
          client: MockClient((request) async => reply(request)),
        ),
      );

  test('signs in without a bearer token and stores both tokens', () async {
    late http.Request sent;
    final auth = repository((request) {
      sent = request;
      return http.Response(
        jsonEncode({'accessToken': 'access', 'refreshToken': 'refresh'}),
        200,
      );
    });

    await auth.signIn(identifier: '+93790000001', password: 'secret');

    expect(sent.url.path, '/api/v1/auth/login');
    expect(sent.headers.containsKey('Authorization'), isFalse);
    expect(jsonDecode(sent.body), {
      'identifier': '+93790000001',
      'password': 'secret',
    });
    expect(await auth.hasSession(), isTrue);
    expect(
      await const FlutterSecureStorage().read(key: 'afghanpay_refresh_token'),
      'refresh',
    );
  });

  test('wrong credentials fail without trying a token refresh', () async {
    var calls = 0;
    final auth = repository((_) {
      calls++;
      return http.Response('', 401);
    });

    await expectLater(
      auth.signIn(identifier: '+93790000001', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
    expect(await auth.hasSession(), isFalse);
  });

  test('a response without tokens is rejected', () async {
    final auth = repository((_) => http.Response(jsonEncode({}), 200));

    await expectLater(
      auth.signIn(identifier: 'x', password: 'y'),
      throwsFormatException,
    );
    expect(await auth.hasSession(), isFalse);
  });
}
