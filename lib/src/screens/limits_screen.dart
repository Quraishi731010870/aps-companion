import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../state/settings.dart';

class LimitsScreen extends ConsumerStatefulWidget {
  const LimitsScreen({super.key});

  @override
  ConsumerState<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends ConsumerState<LimitsScreen> {
  late final TextEditingController daily;
  late final TextEditingController monthly;
  late final TextEditingController count;

  @override
  void initState() {
    super.initState();
    final limits = ref.read(settingsProvider).limits;
    daily = TextEditingController(text: limits.daily.toStringAsFixed(0));
    monthly = TextEditingController(text: limits.monthly.toStringAsFixed(0));
    count = TextEditingController(text: '${limits.dailyCount}');
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
        _AmountField(daily, context.tr('Daily amount limit')),
        const SizedBox(height: 14),
        _AmountField(monthly, context.tr('Monthly amount limit')),
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

  void _save() {
    final saved = ref
        .read(settingsProvider.notifier)
        .updateLimits(
          TransactionLimits(
            daily: double.tryParse(daily.text) ?? 0,
            monthly: double.tryParse(monthly.text) ?? 0,
            dailyCount: int.tryParse(count.text) ?? 0,
          ),
        );
    final message = saved
        ? 'Settings saved'
        : 'Enter valid limits; monthly must be at least daily.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(message))));
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField(this.controller, this.label);
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      suffixText: 'AFN',
      prefixIcon: const Icon(Icons.payments_outlined),
    ),
  );
}
