import 'package:afghan_emi/src/features/settings/data/biometric_authenticator.dart';
import 'package:afghan_emi/src/features/settings/domain/biometric_outcome.dart';
import 'package:afghan_emi/src/features/settings/domain/app_settings.dart';
import 'package:afghan_emi/src/features/settings/presentation/view_models/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthenticator implements BiometricAuthenticator {
  _FakeAuthenticator(this.outcome);
  final BiometricOutcome outcome;

  @override
  Future<BiometricOutcome> verify(String localizedReason) async => outcome;
}

ProviderContainer _container([
  BiometricOutcome outcome = BiometricOutcome.verified,
]) => ProviderContainer.test(
  overrides: [
    biometricAuthenticatorProvider.overrideWithValue(
      _FakeAuthenticator(outcome),
    ),
  ],
);

void main() {
  test('valid limits are saved', () {
    final container = _container();
    const limits = TransactionLimits(daily: 1000, monthly: 5000, dailyCount: 3);

    final saved = container
        .read(settingsProvider.notifier)
        .updateLimits(limits);

    expect(saved, isTrue);
    expect(container.read(settingsProvider).limits, limits);
  });

  test('monthly below daily is rejected and the old limits kept', () {
    final container = _container();
    final before = container.read(settingsProvider).limits;

    final saved = container
        .read(settingsProvider.notifier)
        .updateLimits(
          const TransactionLimits(daily: 5000, monthly: 1000, dailyCount: 3),
        );

    expect(saved, isFalse);
    expect(container.read(settingsProvider).limits, before);
  });

  test('language switch updates the locale code', () {
    final container = _container();
    container.read(settingsProvider.notifier).setLanguage('fa');

    expect(container.read(settingsProvider).isDari, isTrue);
  });

  test('biometrics turn on only after a successful check', () async {
    final verified = _container();
    await verified.read(settingsProvider.notifier).enableBiometric('reason');
    expect(verified.read(settingsProvider).biometricEnabled, isTrue);

    final unavailable = _container(BiometricOutcome.unavailable);
    final outcome = await unavailable
        .read(settingsProvider.notifier)
        .enableBiometric('reason');
    expect(outcome, BiometricOutcome.unavailable);
    expect(unavailable.read(settingsProvider).biometricEnabled, isFalse);
  });
}
