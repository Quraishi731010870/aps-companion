import 'package:flutter/material.dart';

import '../../domain/payment_transaction.dart';

/// One mapping from a transaction state to its icon, colour and label, reused
/// wherever a status is shown.
extension TransactionStateStyle on TransactionState {
  IconData get icon => switch (this) {
    TransactionState.successful => Icons.check_circle_rounded,
    TransactionState.processing => Icons.hourglass_top_rounded,
    TransactionState.failed => Icons.cancel_rounded,
    TransactionState.reversed => Icons.undo_rounded,
  };

  Color color(ColorScheme scheme) => switch (this) {
    TransactionState.successful => scheme.primary,
    TransactionState.processing => scheme.tertiary,
    TransactionState.failed => scheme.error,
    TransactionState.reversed => scheme.outline,
  };

  String get label => switch (this) {
    TransactionState.successful => 'Successful',
    TransactionState.processing => 'Pending',
    TransactionState.failed => 'Failed',
    TransactionState.reversed => 'Reversed',
  };
}
