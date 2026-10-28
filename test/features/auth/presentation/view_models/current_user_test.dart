import 'package:afghan_emi/src/core/config/app_environment.dart';
import 'package:afghan_emi/src/features/auth/data/auth_repository.dart';
import 'package:afghan_emi/src/features/auth/domain/user_profile.dart';
import 'package:afghan_emi/src/features/auth/presentation/view_models/current_user.dart';
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
  container.listen(displayedUserProvider, (_, _) {});
  return container;
}

void main() {
  test('after signing in, the stored user is current and displayed', () async {
    final container = _container(FakeAuthRepository());

    final user = await container.read(currentUserProvider.future);

    expect(user, FakeAuthRepository.testUser);
    expect(container.read(displayedUserProvider), FakeAuthRepository.testUser);
  });

  test(
    'offline mock mode shows the demo user without reading storage',
    () async {
      final auth = FakeAuthRepository();
      final container = _container(auth, environment: const AppEnvironment());

      expect(await container.read(currentUserProvider.future), isNull);
      expect(container.read(displayedUserProvider), UserProfile.demo);
      expect(auth.signIns, isEmpty);
    },
  );

  test('signed out means no current user', () async {
    final container = _container(
      FakeAuthRepository(),
      environment: const AppEnvironment(apiBaseUrl: 'http://localhost:8081'),
    );

    expect(await container.read(currentUserProvider.future), isNull);
    expect(container.read(displayedUserProvider), UserProfile.demo);
  });
}
