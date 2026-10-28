import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/card_number.dart';

part 'linked_card.g.dart';

/// Prototype linked card shared by Home and the payment flow. Holds only the
/// masked label; production must replace this with a vault token (APS p.31).
@Riverpod(keepAlive: true)
class LinkedCard extends _$LinkedCard {
  @override
  String? build() => null;

  /// Masks [cardNumber], stores the label and returns it.
  String link(String cardNumber) => state = CardNumber.masked(cardNumber);
}
