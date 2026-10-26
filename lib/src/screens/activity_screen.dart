import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_payment_gateway.dart';
import '../domain/payment_transaction.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.gateway});
  final PaymentGateway gateway;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<List<WalletActivity>> activities;

  @override
  void initState() {
    super.initState();
    activities = widget.gateway.fetchActivities();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Activity'),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Export CSV report',
              onPressed: () => _export(context),
              icon: const Icon(Icons.download_rounded),
            ),
          ],
        ),
        Text(
          context.tr('Audit-friendly payment history and receipts'),
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: InputDecoration(
            hintText: context.tr('Search transactions'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: const Icon(Icons.tune_rounded),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<WalletActivity>>(
          future: activities,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data ?? mockActivities;
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  children: rows
                      .map((item) => ActivityTile(item: item))
                      .toList(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(
              context.tr('Disputes and reversals'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Production receipts will include fee breakdowns, exchange rates, settlement state and dispute actions.',
            ),
            isThreeLine: true,
          ),
        ),
      ],
    ),
  );

  Future<void> _export(BuildContext context) async {
    final rows = <String>['date,type,amount,currency,source,destination,rrn'];
    for (final item in mockActivities) {
      rows.add(
        '${item.date.toIso8601String()},${item.operation.code},${item.amount},${item.currency},${item.source},${item.destination},${item.rrn}',
      );
    }
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV transaction report copied.')),
    );
  }
}
