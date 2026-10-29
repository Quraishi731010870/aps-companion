import 'package:afghan_emi/src/core/formatting/currency_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groupedAmount adds thousands separators', () {
    expect(groupedAmount(0, 'AFN'), '0 AFN');
    expect(groupedAmount(999, 'AFN'), '999 AFN');
    expect(groupedAmount(24560, 'AFN'), '24,560 AFN');
    expect(groupedAmount(1234567.4, 'USD'), '1,234,567 USD');
    expect(groupedAmount(-1500, 'AFN'), '-1,500 AFN');
  });
}
