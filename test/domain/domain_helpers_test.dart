import 'package:afghan_emi/src/data/mock_payment_gateway.dart';
import 'package:afghan_emi/src/domain/activity_csv.dart';
import 'package:afghan_emi/src/domain/app_settings.dart';
import 'package:afghan_emi/src/domain/card_number.dart';
import 'package:afghan_emi/src/domain/idempotency_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdempotencyKey', () {
    test('is a v4 UUID and unique per call', () {
      final keys = {for (var i = 0; i < 100; i++) IdempotencyKey.generate()};

      expect(keys, hasLength(100));
      expect(
        keys.first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });

  group('CardNumber', () {
    test('accepts 12–19 digits only', () {
      expect(CardNumber.isValid('123456789012'), isTrue);
      expect(CardNumber.isValid('12345678901'), isFalse);
      expect(CardNumber.isValid('12345678901234567890'), isFalse);
      expect(CardNumber.isValid('1234 5678 9012'), isFalse);
    });

    test('masks all but the last four digits', () {
      expect(CardNumber.masked('6037991234561234'), 'APS card  •••• 1234');
    });
  });

  group('TransactionLimits', () {
    const limits = TransactionLimits(daily: 1000, monthly: 5000, dailyCount: 3);

    test('allows amounts within both limits', () {
      expect(limits.allows(1000), isTrue);
      expect(limits.allows(1001), isFalse);
    });

    test('requires monthly to cover daily', () {
      expect(limits.isValid, isTrue);
      expect(
        const TransactionLimits(daily: 10, monthly: 5, dailyCount: 1).isValid,
        isFalse,
      );
    });
  });

  group('ActivityCsv', () {
    test('writes a header plus one quoted row per activity', () {
      final lines = ActivityCsv.encode(mockActivities.take(2)).split('\n');

      expect(lines.first, ActivityCsv.header);
      expect(lines, hasLength(3));
      expect(lines[1], startsWith('"'));
    });
  });

  group('AppSettings', () {
    test('copyWith changes only the given fields', () {
      const original = AppSettings();
      final dari = original.copyWith(languageCode: 'fa');

      expect(dari.isDari, isTrue);
      expect(dari.biometricEnabled, original.biometricEnabled);
      expect(dari.limits, original.limits);
      expect(original.isDari, isFalse);
    });

    test('has value equality so unchanged state does not rebuild', () {
      expect(const AppSettings(), const AppSettings().copyWith());
      expect(
        const AppSettings().hashCode,
        const AppSettings().copyWith().hashCode,
      );
      expect(
        const AppSettings(),
        isNot(const AppSettings(biometricEnabled: true)),
      );
    });
  });
}
