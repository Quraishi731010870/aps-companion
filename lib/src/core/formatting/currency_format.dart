/// Formats an amount in Afghani for display, e.g. `1500 AFN`.
String afn(double value) => '${value.toStringAsFixed(0)} AFN';

/// A balance with thousands separators, e.g. `24,560 AFN`.
String groupedAmount(double value, String currency) {
  final digits = value.abs().toStringAsFixed(0);
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${value < 0 ? '-' : ''}$grouped $currency';
}
