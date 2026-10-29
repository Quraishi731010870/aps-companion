import 'package:afghan_emi/src/features/auth/domain/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes common ways of writing an Afghan mobile number', () {
    for (final input in [
      '+93701234567',
      '+93 70 123 4567',
      '0701234567',
      '701234567',
      '0093701234567',
      '070-123-4567',
    ]) {
      expect(PhoneNumber.normalize(input), '+93701234567', reason: input);
    }
  });

  test('rejects numbers that are not Afghan mobiles', () {
    for (final input in [
      '',
      '12345',
      '+93201234567',
      '+1 555 123 4567',
      '07012345678',
    ]) {
      expect(PhoneNumber.normalize(input), isNull, reason: input);
    }
  });

  test('passwords need at least 10 characters', () {
    expect(PasswordRules.isValid('123456789'), isFalse);
    expect(PasswordRules.isValid('1234567890'), isTrue);
  });
}
