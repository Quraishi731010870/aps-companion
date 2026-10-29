import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/auth_failure.dart';
import 'package:afghan_emi/src/features/auth/domain/session_status.dart';
import 'package:afghan_emi/src/features/auth/presentation/view_models/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../../helpers/test_app.dart';

ProviderContainer _container(
  FakeAuthRepository auth, {
  AppEnvironment environment = backendWithTestUser,
  ApiClient? api,
}) {
  final container = ProviderContainer.test(
    overrides: [
      appEnvironmentProvider.overrideWithValue(environment),
      authRepositoryProvider.overrideWithValue(auth),
      if (api != null) apiClientProvider.overrideWithValue(api),
    ],
  );
  container.listen(sessionProvider, (_, _) {});
  return container;
}

void main() {
  setUp(mockSecureStorage);

  test('offline mock mode needs no sign-in', () async {
    final status = await _container(
      FakeAuthRepository(),
      environment: const AppEnvironment(),
    ).read(sessionProvider.future);

    expect(status, SessionStatus.signedIn);
  });

  test(
    'stored tokens decide; the test user is never signed in on its own',
    () async {
      final auth = FakeAuthRepository();
      expect(
        await _container(auth).read(sessionProvider.future),
        SessionStatus.signedOut,
      );
      expect(auth.signIns, isEmpty);

      expect(
        await _container(FakeAuthRepository(hasTokens: true))
            .read(sessionProvider.future),
        SessionStatus.signedIn,
      );
    },
  );

  test('signing in switches to signed in', () async {
    final auth = FakeAuthRepository();
    final container = _container(auth);
    await container.read(sessionProvider.future);

    await container
        .read(sessionProvider.notifier)
        .signIn(identifier: '+93701234567', password: 'secret-pass');

    expect(container.read(sessionProvider).value, SessionStatus.signedIn);
    expect(auth.signIns, [('+93701234567', 'secret-pass')]);
  });

  test('a failed sign-in throws and stays signed out', () async {
    final auth = FakeAuthRepository()..error = AuthFailure.invalidCredentials;
    final container = _container(auth);
    await container.read(sessionProvider.future);

    await expectLater(
      container
          .read(sessionProvider.notifier)
          .signIn(identifier: '+93701234567', password: 'wrong'),
      throwsA(AuthFailure.invalidCredentials),
    );
    expect(container.read(sessionProvider).value, SessionStatus.signedOut);
  });

  test('registering signs the new customer in', () async {
    final auth = FakeAuthRepository();
    final container = _container(auth);
    await container.read(sessionProvider.future);

    await container
        .read(sessionProvider.notifier)
        .register(
          displayName: 'New Customer',
          phone: '+93701234567',
          password: 'long-password',
        );

    expect(container.read(sessionProvider).value, SessionStatus.signedIn);
    expect(auth.registrations, [
      ('New Customer', '+93701234567', 'long-password'),
    ]);
  });

  test('signing out switches to signed out', () async {
    final auth = FakeAuthRepository(hasTokens: true);
    final container = _container(auth);
    await container.read(sessionProvider.future);

    await container.read(sessionProvider.notifier).signOut();

    expect(container.read(sessionProvider).value, SessionStatus.signedOut);
    expect(auth.signOuts, 1);
  });

  test('a rejected refresh token returns to sign-in', () async {
    final store = SecureStore();
    await store.write(SecureKey.accessToken, 'expired');
    await store.write(SecureKey.refreshToken, 'revoked');
    final api = ApiClient(
      baseUrl: 'http://api.test',
      store: store,
      client: MockClient((_) async => http.Response('', 401)),
    );
    final container = _container(FakeAuthRepository(hasTokens: true), api: api);
    expect(
      await container.read(sessionProvider.future),
      SessionStatus.signedIn,
    );

    await expectLater(
      api.getJson('/api/v1/wallet'),
      throwsA(isA<ApiException>()),
    );
    await pumpEventQueue();

    expect(container.read(sessionProvider).value, SessionStatus.signedOut);
  });
}
