import 'package:afghan_emi/src/data/biometric_authenticator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

class _FakeLocalAuth extends Fake implements LocalAuthentication {
  _FakeLocalAuth({
    this.supported = true,
    this.enrolled = true,
    this.verified = true,
    this.throws = false,
  });
  final bool supported;
  final bool enrolled;
  final bool verified;
  final bool throws;
  String? reason;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> get canCheckBiometrics async => enrolled;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    // Wider than the platform's AuthMessages type, which local_auth
    // does not export.
    Iterable<Object?> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    if (throws) throw Exception('platform failure');
    reason = localizedReason;
    return verified;
  }
}

void main() {
  test('verified when the platform check passes', () async {
    final platform = _FakeLocalAuth();
    final outcome = await BiometricAuthenticator(platform).verify('Unlock');

    expect(outcome, BiometricOutcome.verified);
    expect(platform.reason, 'Unlock');
  });

  test('cancelled when the user dismisses the prompt', () async {
    final outcome = await BiometricAuthenticator(
      _FakeLocalAuth(verified: false),
    ).verify('Unlock');
    expect(outcome, BiometricOutcome.cancelled);
  });

  test('unavailable when the device has no support or enrolment', () async {
    expect(
      await BiometricAuthenticator(_FakeLocalAuth(supported: false))
          .verify('Unlock'),
      BiometricOutcome.unavailable,
    );
    expect(
      await BiometricAuthenticator(_FakeLocalAuth(enrolled: false))
          .verify('Unlock'),
      BiometricOutcome.unavailable,
    );
  });

  test('platform errors are reported as unavailable, never thrown', () async {
    final outcome = await BiometricAuthenticator(_FakeLocalAuth(throws: true))
        .verify('Unlock');
    expect(outcome, BiometricOutcome.unavailable);
  });
}
