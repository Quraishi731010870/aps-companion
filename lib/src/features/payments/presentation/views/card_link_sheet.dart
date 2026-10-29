import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/view_models/current_user.dart';
import '../../domain/card_details.dart';
import '../../domain/card_number.dart';
import '../view_models/linked_card.dart';

Future<String?> showCardLinkSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CardLinkSheet(),
    );

class _CardLinkSheet extends ConsumerStatefulWidget {
  const _CardLinkSheet();

  @override
  ConsumerState<_CardLinkSheet> createState() => _CardLinkSheetState();
}

class _CardLinkSheetState extends ConsumerState<_CardLinkSheet> {
  final formKey = GlobalKey<FormState>();
  bool _saving = false;
  final cardNumber = TextEditingController();
  final expiry = TextEditingController();
  late final name = TextEditingController(
    text: ref.read(displayedUserProvider).displayName,
  );

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
            validator: (value) => CardNumber.isValid(value ?? '')
                ? null
                : 'Enter a valid card number',
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
                      switch (CardDetails.parseExpiry(value ?? '')) {
                        null => 'Use MM/YY',
                        (final month, final year)
                            when CardDetails.isExpired(
                              month,
                              year,
                              DateTime.now(),
                            ) =>
                          context.tr('This card has expired'),
                        _ => null,
                      },
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
              onPressed: _saving ? null : _link,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(context.tr('Link card')),
            ),
          ),
        ],
      ),
    ),
  );

  /// Encrypts the card and vaults it; only the token and masked number come
  /// back to the device.
  Future<void> _link() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final (month, year) = CardDetails.parseExpiry(expiry.text) ?? (null, null);
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(linkedCardProvider.notifier)
          .link(
            CardDetails(
              pan: cardNumber.text.trim(),
              expiryMonth: month,
              expiryYear: year,
              holderName: name.text,
            ),
          );
      if (mounted) Navigator.pop(context, saved.label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('The card could not be saved. Please try again.'),
          ),
        ),
      );
    }
  }
}
