import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../payments/presentation/view_models/enabled_operations.dart';
import '../../../payments/presentation/views/payment_flow.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});
  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final operations = ref
        .watch(enabledOperationsProvider)
        .where(
          (item) => '${item.label} ${item.code}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            context.tr('EMI services'),
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            context.tr('All supported financial transaction rails'),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: context.tr('Search name or transaction code'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: operations.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final item = operations[index];
                return ListTile(
                  onTap: () => openPaymentFlow(context, item),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xffe7f3ef),
                    child: Icon(item.icon, color: const Color(0xff087f67)),
                  ),
                  title: Text(
                    context.tr(item.label),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Transaction type ${item.code} • ${item.requiresAmount ? 'Financial' : 'Inquiry'}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('Additional consumer services'),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _Extra(
                  Icons.phone_android_rounded,
                  context.tr('Mobile top-up & data'),
                  'Afghan Wireless, Roshan, MTN, Etisalat, Salaam',
                ),
                const Divider(height: 1, indent: 70),
                _Extra(
                  Icons.bolt_rounded,
                  context.tr('Utility bills'),
                  'Electricity, water and internet',
                ),
                const Divider(height: 1, indent: 70),
                _Extra(
                  Icons.school_outlined,
                  context.tr('Education & government'),
                  'Fees and public services',
                ),
                const Divider(height: 1, indent: 70),
                _Extra(
                  Icons.storefront_outlined,
                  context.tr('Merchant services'),
                  'QR acceptance, settlement and reports',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Extra extends StatelessWidget {
  const _Extra(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(child: Icon(icon)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.lock_clock_outlined),
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Provider adapter ready for backend integration.'),
      ),
    ),
  );
}
