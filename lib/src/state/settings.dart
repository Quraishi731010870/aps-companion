import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/biometric_authenticator.dart';
import '../domain/app_settings.dart';

part 'settings.g.dart';

/// ViewModel for language, biometric unlock and transaction limits.
@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  AppSettings build() => const AppSettings();

  void setLanguage(String languageCode) =>
      state = state.copyWith(languageCode: languageCode);

  void disableBiometric() => state = state.copyWith(biometricEnabled: false);

  /// Enables biometrics only after the user passes a biometric check.
  Future<BiometricOutcome> enableBiometric(String localizedReason) async {
    final outcome = await ref
        .read(biometricAuthenticatorProvider)
        .verify(localizedReason);
    if (!ref.mounted) return outcome;
    if (outcome == BiometricOutcome.verified) {
      state = state.copyWith(biometricEnabled: true);
    }
    return outcome;
  }

  /// Returns false and keeps the current limits when [limits] is invalid.
  bool updateLimits(TransactionLimits limits) {
    if (!limits.isValid) return false;
    state = state.copyWith(limits: limits);
    return true;
  }
}
