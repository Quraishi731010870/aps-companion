import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/core/network/api_client.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/session_status.dart';
import 'package:afghan_emi/src/features/auth/presentation/view_models/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

ProviderContainer _container(
  FakeAuthRepository auth, {
  AppEnvironment environment = backendWithTestUser,
}) {
  final container = ProviderContainer.test(
    overrides: [
      appEnvironmentProvider.overrideWithValue(environment),
      authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  container.listen(sessionProvider, (_, _) {});
  return container;
}

void main() {
  test('offline mock mode needs no sign-in', () async {
    final auth = FakeAuthRepository();
    final status = await _container(
      auth,
      environment: const AppEnvironment(),
    ).read(sessionProvider.future);

    expect(status, SessionStatus.signedIn);
    expect(auth.signIns, isEmpty);
  });

  test('signs in as the configured test user', () async {
    final auth = FakeAuthRepository();
    final status = await _container(auth).read(sessionProvider.future);

    expect(status, SessionStatus.signedIn);
    expect(auth.signIns, [('+93790000001', 'test-password')]);
  });

  test('without a test user, stored tokens decide', () async {
    const noTestUser = AppEnvironment(apiBaseUrl: 'http://localhost:8081');

    final signedOut = await _container(
      FakeAuthRepository(),
      environment: noTestUser,
    ).read(sessionProvider.future);
    expect(signedOut, SessionStatus.signedOut);

    final signedIn = await _container(
      FakeAuthRepository(hasTokens: true),
      environment: noTestUser,
    ).read(sessionProvider.future);
    expect(signedIn, SessionStatus.signedIn);
  });

  test('release builds ignore test-user credentials', () async {
    final auth = FakeAuthRepository();
    final status = await _container(
      auth,
      environment: const AppEnvironment(
        apiBaseUrl: 'http://localhost:8081',
        testUserIdentifier: '+93790000001',
        testUserPassword: 'test-password',
        isRelease: true,
      ),
    ).read(sessionProvider.future);

    expect(status, SessionStatus.signedOut);
    expect(auth.signIns, isEmpty);
  });

  test('a failed sign-in is an error that retry can recover from', () async {
    final auth = FakeAuthRepository()
      ..error = const ApiException(401, 'Invalid credentials');
    final container = _container(auth);

    await expectLater(
      container.read(sessionProvider.future),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(sessionProvider).hasError, isTrue);

    auth.error = null;
    await container.read(sessionProvider.notifier).retry();

    expect(container.read(sessionProvider).value, SessionStatus.signedIn);
  });
}
