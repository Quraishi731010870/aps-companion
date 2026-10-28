import 'package:flutter/material.dart';

import '../domain/payment_transaction.dart';
import '../l10n/app_localizations.dart';
import '../screens/receipt_screen.dart';
import 'payment_flow.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item});
  final WalletActivity item;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ReceiptScreen(activity: item))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    leading: CircleAvatar(
      backgroundColor: const Color(0xffedf4f1),
      child: Icon(item.operation.icon, color: const Color(0xff087f67)),
    ),
    title: Text(
      context.tr(item.title),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${item.subtitle} • ${item.operation.code}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Text(
      '${item.incoming ? '+' : '−'} ${afn(item.amount)}',
      style: TextStyle(
        color: item.incoming ? const Color(0xff087f67) : Colors.black87,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
