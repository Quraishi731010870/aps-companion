import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/card_number.dart';
import '../../domain/saved_card.dart';

/// Shows the linked [card] (masked number only). Resolves to `true` when the
/// user asks to replace it.
Future<bool?> showSavedCardSheet(BuildContext context, SavedCard card) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SavedCardSheet(card),
    );

class _SavedCardSheet extends StatelessWidget {
  const _SavedCardSheet(this.card);
  final SavedCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiry = switch ((card.expiryMonth, card.expiryYear)) {
      (final int month, final int year) =>
        '${month.toString().padLeft(2, '0')}/'
            '${(year % 100).toString().padLeft(2, '0')}',
      _ => null,
    };
    final holder = card.holderName?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
            context.tr('Your linked card'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            context.tr('Linked securely to your PayAfghan wallet'),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.credit_card_rounded),
                  title: Text(context.tr('Card number')),
                  subtitle: Text(CardNumber.display(card.maskedPan)),
                ),
                if (holder != null && holder.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(context.tr('Cardholder')),
                    subtitle: Text(holder),
                  ),
                if (expiry != null)
                  ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(context.tr('Expiry')),
                    subtitle: Text(expiry),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(context.tr('Replace card')),
            ),
          ),
        ],
      ),
    );
  }
}
