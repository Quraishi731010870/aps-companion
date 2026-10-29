import 'dart:convert';

import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/core/security/device_key_signer.dart';
import 'package:afghan_emi/src/core/security/request_signature.dart';
import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/auth_failure.dart';
import 'package:afghan_emi/src/features/auth/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../helpers/test_app.dart';

Map<String, Object> _loginResponse({String type = 'MOBILE_USER'}) => {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'displayName': 'Demo Customer 001',
  'principal': {
    'sub': 'user-1',
    'type': type,
    'sessionId': 'session-1',
    'roles': <String>[],
    'permissions': <String>[],
  },
};

void main() {
  late SecureStore store;
  late DeviceKeySigner signer;

  setUp(() {
    mockSecureStorage();
    store = SecureStore();
    signer = DeviceKeySigner(store);
  });

  AuthRepository repository(http.Response Function(http.Request) reply) =>
      AuthRepository(
        ApiClient(
          baseUrl: 'http://api.test',
          client: MockClient((request) async => reply(request)),
          store: store,
          signer: signer,
        ),
        store,
        signer,
      );

  test('signs in without a bearer token and stores tokens and user', () async {
    late http.Request sent;
    final auth = repository((request) {
      sent = request;
      return http.Response(jsonEncode(_loginResponse()), 200);
    });

    final profile = await auth.signIn(
      identifier: '+93790000001',
      password: 'secret',
    );

    expect(sent.url.path, '/api/v1/auth/login');
    expect(sent.headers.containsKey('Authorization'), isFalse);
    final device = await signer.binding();
    expect(jsonDecode(sent.body), {
      'identifier': '+93790000001',
      'password': 'secret',
      'device': device.toJson(),
    });
    expect(device.publicKey, hasLength(43));
    expect(sent.headers[RequestSignature.signatureHeader], hasLength(86));
    const expected = UserProfile(
      id: 'user-1',
      displayName: 'Demo Customer 001',
    );
    expect(profile, expected);
    expect(await auth.currentUser(), expected);
    expect(await auth.hasSession(), isTrue);
    expect(await store.read(SecureKey.refreshToken), 'refresh');
  });

  test('never stores the password, roles or session id', () async {
    final auth = repository(
      (_) => http.Response(jsonEncode(_loginResponse()), 200),
    );
    await auth.signIn(identifier: '+93790000001', password: 'secret');

    final stored = await store.read(SecureKey.userProfile);
    expect(stored, isNot(contains('secret')));
    expect(stored, isNot(contains('session-1')));
    expect(stored, isNot(contains('permissions')));
  });

  test('administrator accounts are refused and nothing is stored', () async {
    final auth = repository(
      (_) => http.Response(jsonEncode(_loginResponse(type: 'ADMIN')), 200),
    );

    await expectLater(
      auth.signIn(identifier: 'admin@afghanpay.test', password: 'x'),
      throwsA(AuthFailure.notAllowed),
    );
    expect(await auth.hasSession(), isFalse);
    expect(await auth.currentUser(), isNull);
  });

  test('wrong credentials fail without trying a token refresh', () async {
    var calls = 0;
    final auth = repository((_) {
      calls++;
      return http.Response('{"code":"INVALID_CREDENTIALS"}', 401);
    });

    await expectLater(
      auth.signIn(identifier: '+93790000001', password: 'wrong'),
      throwsA(AuthFailure.invalidCredentials),
    );
    expect(calls, 1);
    expect(await auth.hasSession(), isFalse);
  });

  test('backend error codes become typed failures', () async {
    final cases = {
      '{"code":"ACCOUNT_LOCKED"}': AuthFailure.accountLocked,
      '{"code":"PHONE_IN_USE"}': AuthFailure.phoneInUse,
      '{"code":"REGISTRATION_DISABLED"}': AuthFailure.registrationClosed,
      '<html>gateway error</html>': AuthFailure.unknown,
    };
    for (final MapEntry(key: body, value: failure) in cases.entries) {
      final auth = repository((_) => http.Response(body, 409));
      await expectLater(
        auth.register(displayName: 'A', phone: '+93701234567', password: 'x'),
        throwsA(failure),
        reason: body,
      );
    }
  });

  test(
    'registering posts the new customer with this device and signs in',
    () async {
      late http.Request sent;
      final auth = repository((request) {
        sent = request;
        return http.Response(jsonEncode(_loginResponse()), 201);
      });

      final profile = await auth.register(
        displayName: 'New Customer',
        phone: '+93701234567',
        password: 'long-password',
      );

      expect(sent.url.path, '/api/v1/auth/register');
      expect(jsonDecode(sent.body), {
        'displayName': 'New Customer',
        'phone': '+93701234567',
        'password': 'long-password',
        'device': (await signer.binding()).toJson(),
      });
      expect(profile.id, 'user-1');
      expect(await auth.hasSession(), isTrue);
    },
  );

  test(
    'signing out revokes the server session and clears the device',
    () async {
      final paths = <String>[];
      final auth = repository((request) {
        paths.add(request.url.path);
        return http.Response(jsonEncode(_loginResponse()), 200);
      });
      await auth.signIn(identifier: '+93790000001', password: 'secret');

      await auth.signOut();

      expect(paths.last, '/api/v1/auth/logout');
      expect(await auth.hasSession(), isFalse);
      expect(await auth.currentUser(), isNull);
    },
  );

  test('signing out offline still clears the local session', () async {
    var online = true;
    final auth = repository((_) {
      if (!online) throw http.ClientException('offline');
      return http.Response(jsonEncode(_loginResponse()), 200);
    });
    await auth.signIn(identifier: '+93790000001', password: 'secret');
    online = false;

    await auth.signOut();

    expect(await auth.hasSession(), isFalse);
  });

  test('a response without tokens or principal is rejected', () async {
    final auth = repository(
      (_) => http.Response(jsonEncode({'accessToken': 'a'}), 200),
    );

    await expectLater(
      auth.signIn(identifier: 'x', password: 'y'),
      throwsFormatException,
    );
    expect(await auth.hasSession(), isFalse);
  });

  test('an unreadable stored profile is treated as no user', () async {
    await store.write(SecureKey.userProfile, 'not json');
    final auth = repository((_) => http.Response('', 500));

    expect(await auth.currentUser(), isNull);
  });

  test('sign-out removes tokens and the profile', () async {
    final auth = repository(
      (_) => http.Response(jsonEncode(_loginResponse()), 200),
    );
    await auth.signIn(identifier: '+93790000001', password: 'secret');

    await auth.signOut();

    expect(await auth.hasSession(), isFalse);
    expect(await auth.currentUser(), isNull);
  });
}
