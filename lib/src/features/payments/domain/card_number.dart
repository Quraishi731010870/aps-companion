/// Card number rules shared by every card form, so validation and masking
/// live in one place.
abstract final class CardNumber {
  static const minLength = 12;
  static const maxLength = 19;

  static bool isValid(String digits) {
    final value = digits.trim();
    return value.length >= minLength &&
        value.length <= maxLength &&
        RegExp(r'^\d+$').hasMatch(value);
  }

  /// PCI-permitted form: first six and last four digits, e.g.
  /// `603799******1234`. Matches the backend's `maskPan`.
  static String masked(String digits) {
    final value = digits.trim();
    return '${value.substring(0, 6)}'
        '${'*' * (value.length - 10)}'
        '${value.substring(value.length - 4)}';
  }

  /// Groups a masked number in fours for display: `6037 99** **** 1234`.
  static String display(String masked) => [
    for (var i = 0; i < masked.length; i += 4)
      masked.substring(i, i + 4 > masked.length ? masked.length : i + 4),
  ].join(' ');
}
