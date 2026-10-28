import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_authenticator.g.dart';

enum BiometricOutcome { verified, cancelled, unavailable }

/// Wraps the platform biometric API so view models stay testable.
class BiometricAuthenticator {
  BiometricAuthenticator([LocalAuthentication? authentication])
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  Future<BiometricOutcome> verify(String localizedReason) async {
    try {
      final supported = await _authentication.isDeviceSupported();
      final enrolled = await _authentication.canCheckBiometrics;
      if (!supported || !enrolled) return BiometricOutcome.unavailable;
      final verified = await _authentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return verified ? BiometricOutcome.verified : BiometricOutcome.cancelled;
    } catch (_) {
      return BiometricOutcome.unavailable;
    }
  }
}

@Riverpod(keepAlive: true)
BiometricAuthenticator biometricAuthenticator(Ref ref) =>
    BiometricAuthenticator();
