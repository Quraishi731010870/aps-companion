import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/payment_transaction.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.activity});
  final WalletActivity activity;

  @override
  Widget build(BuildContext context) {
    final receipt = _receiptText(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Transaction receipt'))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 62,
                    color: Color(0xff087f67),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('Successful'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${activity.incoming ? '+' : '−'} ${activity.amount.toStringAsFixed(0)} ${activity.currency}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _row(context.tr('Date & time'), _date(activity.date)),
                  _row(
                    context.tr('Transaction type'),
                    '${activity.operation.label} (${activity.operation.code})',
                  ),
                  _row(context.tr('Source'), activity.source),
                  _row(context.tr('Destination'), activity.destination),
                  _row(context.tr('Card number'), activity.cardNumber),
                  _row(context.tr('RRN / UTR'), activity.rrn),
                  _row(context.tr('Currency'), activity.currency),
                  _row(
                    context.tr('Fee'),
                    '${activity.fee.toStringAsFixed(0)} ${activity.currency}',
                  ),
                  _row(context.tr('Status'), context.tr('Successful')),
                  _row('Channel', 'PayAfghan Mobile'),
                  _row('Institution', 'Afghan EMI / APS'),
                  _row('Authorization code', activity.rrn.substring(0, 6)),
                  _row('Settlement status', 'Settled'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copy(context, receipt, 'Receipt copied'),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(context.tr('Download receipt')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _copy(context, receipt, 'Receipt ready to share'),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(context.tr('Share receipt')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Prototype receipt. Backend settlement, cryptographic signing and dispute APIs will be connected later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';

  String _receiptText(BuildContext context) =>
      '''PayAfghan transaction receipt
Status: Successful
Amount: ${activity.amount.toStringAsFixed(0)} ${activity.currency}
Date: ${_date(activity.date)}
Type: ${activity.operation.label} (${activity.operation.code})
Source: ${activity.source}
Destination: ${activity.destination}
Card: ${activity.cardNumber}
RRN/UTR: ${activity.rrn}
Fee: ${activity.fee.toStringAsFixed(0)} ${activity.currency}''';

  Future<void> _copy(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
