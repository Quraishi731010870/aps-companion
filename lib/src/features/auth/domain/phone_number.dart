/// Afghan mobile numbers in the form the backend stores: `+937XXXXXXXX`.
abstract final class PhoneNumber {
  static final _valid = RegExp(r'^\+937\d{8}$');

  /// Accepts `+93 70 123 4567`, `0701234567` or `701234567`; returns the
  /// `+937XXXXXXXX` form, or null when it is not an Afghan mobile number.
  static String? normalize(String input) {
    final digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
    final candidate = switch (digits) {
      final value when value.startsWith('+93') => value,
      final value when value.startsWith('0093') => '+${value.substring(2)}',
      final value when value.startsWith('0') => '+93${value.substring(1)}',
      final value => '+93$value',
    };
    return _valid.hasMatch(candidate) ? candidate : null;
  }
}

/// Matches the backend's `RegisterDto` rules.
abstract final class PasswordRules {
  static const minLength = 10;

  static bool isValid(String value) =>
      value.length >= minLength && value.length <= 200;
}
