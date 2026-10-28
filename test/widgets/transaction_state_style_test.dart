import 'package:afghan_emi/src/domain/payment_transaction.dart';
import 'package:afghan_emi/src/widgets/transaction_state_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xff087f67));

  test('every state has a distinct icon and label', () {
    final icons = {for (final state in TransactionState.values) state.icon};
    final labels = {for (final state in TransactionState.values) state.label};

    expect(icons, hasLength(TransactionState.values.length));
    expect(labels, hasLength(TransactionState.values.length));
  });

  test('only success uses the success colour and tick', () {
    expect(TransactionState.successful.icon, Icons.check_circle_rounded);
    expect(TransactionState.successful.color(scheme), scheme.primary);
    expect(TransactionState.failed.color(scheme), scheme.error);
    expect(TransactionState.processing.label, 'Pending');
    for (final state in TransactionState.values) {
      if (state == TransactionState.successful) continue;
      expect(state.icon, isNot(Icons.check_circle_rounded));
    }
  });
}
