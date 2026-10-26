import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class LimitsScreen extends StatefulWidget {
  const LimitsScreen({super.key});

  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen> {
  final daily = TextEditingController();
  final monthly = TextEditingController();
  final count = TextEditingController();
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final state = AppScope.of(context);
    daily.text = state.dailyLimit.toStringAsFixed(0);
    monthly.text = state.monthlyLimit.toStringAsFixed(0);
    count.text = '${state.transactionCountLimit}';
    initialized = true;
  }

  @override
  void dispose() {
    daily.dispose();
    monthly.dispose();
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Transaction limits'))),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _amountField(daily, context.tr('Daily amount limit')),
        const SizedBox(height: 14),
        _amountField(monthly, context.tr('Monthly amount limit')),
        const SizedBox(height: 14),
        TextField(
          controller: count,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: context.tr('Daily transaction count'),
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: Text(context.tr('Limit cycle')),
            subtitle: Text(
              context.tr('Daily: 00:00 • Monthly: first day at 00:00'),
            ),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(context.tr('Save limits')),
        ),
      ],
    ),
  );

  TextField _amountField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          suffixText: 'AFN',
          prefixIcon: const Icon(Icons.payments_outlined),
        ),
      );

  void _save() {
    final dailyValue = double.tryParse(daily.text) ?? 0;
    final monthlyValue = double.tryParse(monthly.text) ?? 0;
    final countValue = int.tryParse(count.text) ?? 0;
    if (dailyValue <= 0 || monthlyValue < dailyValue || countValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid limits; monthly must be at least daily.'),
        ),
      );
      return;
    }
    AppScope.of(context)
        .setLimits(daily: dailyValue, monthly: monthlyValue, count: countValue);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('Settings saved'))));
  }
}
