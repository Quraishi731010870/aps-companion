import 'package:flutter/material.dart';

enum PaymentOperation {
  balanceInquiry(
    702,
    'Balance Inquiry',
    Icons.account_balance_wallet_outlined,
    false,
  ),
  nameInquiry(651, 'Name Inquiry', Icons.person_search_outlined, false),
  walletToCard(785, 'W2C (Bank Push)', Icons.account_balance_outlined, true),
  cardToWallet(781, 'C2W (Bank Pull)', Icons.move_to_inbox_outlined, true),
  cardToCard(689, 'P2P (Card to Card)', Icons.swap_horiz_rounded, true),
  purchase(774, 'Purchase', Icons.shopping_bag_outlined, true),
  billInfo(511, 'Bill Info', Icons.receipt_long_outlined, false),
  billPayment(512, 'Bill Payment', Icons.request_quote_outlined, true),
  savePayment(508, 'Save Payment', Icons.bookmark_add_outlined, false),
  cashIn(618, 'Cash-In', Icons.add_card_outlined, true),
  cashOut(700, 'Cash-Out', Icons.point_of_sale_outlined, true);

  const PaymentOperation(this.code, this.label, this.icon, this.requiresAmount);
  final int code;
  final String label;
  final IconData icon;
  final bool requiresAmount;
  String get configurationKey => switch (this) {
    PaymentOperation.balanceInquiry => 'balance_inquiry',
    PaymentOperation.nameInquiry => 'card_title_fetch',
    PaymentOperation.walletToCard => 'wallet_to_card',
    PaymentOperation.cardToWallet => 'card_to_wallet',
    PaymentOperation.cardToCard => 'card_to_card',
    PaymentOperation.purchase => 'purchase',
    PaymentOperation.billInfo => 'payment_info',
    PaymentOperation.billPayment => 'bill_payment',
    PaymentOperation.savePayment => 'save_payment',
    PaymentOperation.cashIn => 'cash_in',
    PaymentOperation.cashOut => 'cash_out',
  };
}

enum TransactionState { processing, successful, failed, reversed }

class PaymentRequest {
  const PaymentRequest({
    required this.operation,
    required this.source,
    required this.destination,
    required this.amount,
    required this.reference,
    required this.idempotencyKey,
  });

  final PaymentOperation operation;
  final String source;
  final String destination;
  final double amount;
  final String reference;
  final String idempotencyKey;

  Map<String, Object> toJson() => {
    'transactionType': operation.code,
    'source': source,
    'destination': destination,
    'amount': amount,
    'currency': 'AFN',
    'reference': reference,
    'idempotencyKey': idempotencyKey,
  };
}

class PaymentResult {
  const PaymentResult({
    required this.request,
    required this.transactionId,
    required this.state,
    required this.message,
    required this.createdAt,
  });
  final PaymentRequest request;
  final String transactionId;
  final TransactionState state;
  final String message;
  final DateTime createdAt;
}

class WalletActivity {
  const WalletActivity({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.incoming,
    required this.operation,
    required this.date,
    required this.source,
    required this.destination,
    required this.rrn,
    this.cardNumber = '•••• 1087',
    this.currency = 'AFN',
    this.fee = 0,
    this.status = TransactionState.successful,
  });
  final String title;
  final String subtitle;
  final double amount;
  final bool incoming;
  final PaymentOperation operation;
  final DateTime date;
  final String source;
  final String destination;
  final String rrn;
  final String cardNumber;
  final String currency;
  final double fee;
  final TransactionState status;
}
