import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/view_models/session.dart';
import '../../data/card_vault_provider.dart';
import '../../domain/card_details.dart';
import '../../domain/saved_card.dart';

part 'linked_card.g.dart';

/// The card linked on this device, shared by Home and the payment flow.
/// Holds only the vault token and masked number (APS p.31).
@Riverpod(keepAlive: true)
class LinkedCard extends _$LinkedCard {
  @override
  Future<SavedCard?> build() async {
    // Reload when the user changes; sign-out clears the stored card.
    await ref.watch(sessionProvider.future);
    return ref.watch(cardVaultProvider).linkedCard();
  }

  /// Encrypts [card], vaults it on the backend and links the returned token.
  Future<SavedCard> link(CardDetails card) async {
    final saved = await ref.read(cardVaultProvider).saveCard(card);
    if (ref.mounted) state = AsyncData(saved);
    return saved;
  }
}
