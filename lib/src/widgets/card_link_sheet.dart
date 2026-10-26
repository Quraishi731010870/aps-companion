import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Prototype-only in-memory card token shared by card linking and payments.
/// A production app must replace this with a token returned by the card issuer.
final class LinkedCardStore {
  LinkedCardStore._();

  static final ValueNotifier<String?> card = ValueNotifier<String?>(null);
}

Future<String?> showCardLinkSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CardLinkSheet(),
    );

class _CardLinkSheet extends StatefulWidget {
  const _CardLinkSheet();

  @override
  State<_CardLinkSheet> createState() => _CardLinkSheetState();
}

class _CardLinkSheetState extends State<_CardLinkSheet> {
  final formKey = GlobalKey<FormState>();
  final cardNumber = TextEditingController();
  final expiry = TextEditingController();
  final name = TextEditingController(text: 'Asif Quraishi');

  @override
  void dispose() {
    cardNumber.dispose();
    expiry.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr('Link your card'),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            context.tr(
              'Connect an APS-enabled card to use bank pull and card payments.',
            ),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: cardNumber,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.creditCardNumber],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.tr('Card number'),
              prefixIcon: const Icon(Icons.credit_card_rounded),
            ),
            validator: (value) {
              final digits = value?.trim() ?? '';
              return digits.length < 12 || digits.length > 19
                  ? 'Enter a valid card number'
                  : null;
            },
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiry,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: const InputDecoration(labelText: 'Expiry MM/YY'),
                  validator: (value) =>
                      RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(value ?? '')
                      ? null
                      : 'Use MM/YY',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Cardholder'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: Color(0xff087f67)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Testing only. Production card linking requires bank verification and tokenization.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final digits = cardNumber.text;
                final linkedCard =
                    'APS card  •••• ${digits.substring(digits.length - 4)}';
                LinkedCardStore.card.value = linkedCard;
                Navigator.pop(context, linkedCard);
              },
              icon: const Icon(Icons.link_rounded),
              label: Text(context.tr('Link card')),
            ),
          ),
        ],
      ),
    ),
  );
}
