/// Card number rules shared by every card form, so validation and masking
/// live in one place. The full number is never stored.
abstract final class CardNumber {
  static const minLength = 12;
  static const maxLength = 19;

  static bool isValid(String digits) {
    final value = digits.trim();
    return value.length >= minLength &&
        value.length <= maxLength &&
        RegExp(r'^\d+$').hasMatch(value);
  }

  /// Display label that keeps only the last four digits.
  static String masked(String digits) {
    final value = digits.trim();
    return 'APS card  •••• ${value.substring(value.length - 4)}';
  }
}
