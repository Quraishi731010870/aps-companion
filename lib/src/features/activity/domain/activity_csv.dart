import '../../payments/domain/payment_transaction.dart';

/// CSV export of wallet history. Fields are quoted so commas in names or
/// references cannot break columns.
abstract final class ActivityCsv {
  static const header = 'date,type,amount,currency,source,destination,rrn';

  static String encode(Iterable<WalletActivity> activities) => [
    header,
    for (final item in activities)
      [
        item.date.toIso8601String(),
        '${item.operation.code}',
        '${item.amount}',
        item.currency,
        item.source,
        item.destination,
        item.rrn,
      ].map(_quote).join(','),
  ].join('\n');

  static String _quote(String value) => '"${value.replaceAll('"', '""')}"';
}
