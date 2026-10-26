import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_payment_gateway.dart';
import '../domain/payment_transaction.dart';
import '../domain/wallet_identity.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/receipt_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import 'card_link_sheet.dart';

String afn(double value) => '${value.toStringAsFixed(0)} AFN';

Future<void> openPaymentFlow(
  BuildContext context,
  PaymentGateway gateway,
  PaymentOperation operation, {
  bool scanQrOnOpen = false,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PaymentFlowScreen(
        operation: operation,
        gateway: gateway,
        scanQrOnOpen: scanQrOnOpen,
      ),
    ),
  );
}

enum PaymentFundingSource { wallet, linkedCard, manualCard }

class PaymentFlowScreen extends StatefulWidget {
  const PaymentFlowScreen({
    super.key,
    required this.operation,
    required this.gateway,
    this.scanQrOnOpen = false,
  });
  final PaymentOperation operation;
  final PaymentGateway gateway;
  final bool scanQrOnOpen;

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> {
  final formKey = GlobalKey<FormState>();
  final source = TextEditingController();
  final destination = TextEditingController();
  final amount = TextEditingController();
  final reference = TextEditingController();
  bool loading = false;
  late PaymentFundingSource fundingSource;
  String biller = 'DABS Electricity';

  @override
  void initState() {
    super.initState();
    fundingSource = _walletCanFund(widget.operation)
        ? PaymentFundingSource.wallet
        : LinkedCardStore.card.value == null
        ? PaymentFundingSource.manualCard
        : PaymentFundingSource.linkedCard;
    _syncSource();
    if (widget.scanQrOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scanQrCode();
      });
    }
  }

  @override
  void dispose() {
    source.dispose();
    destination.dispose();
    amount.dispose();
    reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.operation.label)),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xffe6f3ef),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xff087f67),
                    child: Icon(widget.operation.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(widget.operation.label),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Transaction type ${widget.operation.code}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.operation.requiresAmount) ...[
              Text(
                context.tr('Pay with'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: RadioGroup<PaymentFundingSource>(
                  groupValue: fundingSource,
                  onChanged: _selectFundingSource,
                  child: Column(
                    children: [
                      if (_walletCanFund(widget.operation))
                        RadioListTile<PaymentFundingSource>(
                          value: PaymentFundingSource.wallet,
                          secondary: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          title: Text(
                            context.tr('Use wallet number as a card'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'PayAfghan wallet ${WalletIdentity.masked}',
                          ),
                        ),
                      if (_walletCanFund(widget.operation))
                        const Divider(height: 1, indent: 56),
                      RadioListTile<PaymentFundingSource>(
                        value: PaymentFundingSource.linkedCard,
                        enabled: LinkedCardStore.card.value != null,
                        secondary: const Icon(Icons.link_rounded),
                        title: Text(
                          context.tr('Use linked card'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          LinkedCardStore.card.value ??
                              context.tr(
                                'No card linked — link one from Home first',
                              ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      RadioListTile<PaymentFundingSource>(
                        value: PaymentFundingSource.manualCard,
                        secondary: const Icon(Icons.keyboard_alt_outlined),
                        title: Text(
                          context.tr('Enter card manually'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          context.tr('Type the card number for this payment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.operation.requiresAmount &&
                fundingSource == PaymentFundingSource.manualCard) ...[
              const SizedBox(height: 13),
              TextFormField(
                controller: source,
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
            ],
            const SizedBox(height: 13),
            if (widget.operation == PaymentOperation.billInfo ||
                widget.operation == PaymentOperation.billPayment ||
                widget.operation == PaymentOperation.savePayment) ...[
              DropdownButtonFormField<String>(
                initialValue: biller,
                decoration: InputDecoration(
                  labelText: context.tr('Biller'),
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'DABS Electricity',
                    child: Text('DABS Electricity'),
                  ),
                  DropdownMenuItem(
                    value: 'AUWSSC Water',
                    child: Text('AUWSSC Water'),
                  ),
                  DropdownMenuItem(
                    value: 'Afghan Telecom',
                    child: Text('Afghan Telecom'),
                  ),
                  DropdownMenuItem(
                    value: 'Municipality',
                    child: Text('Municipality'),
                  ),
                ],
                onChanged: (value) => biller = value!,
              ),
              const SizedBox(height: 13),
            ],
            TextFormField(
              controller: destination,
              decoration: InputDecoration(
                labelText: context.tr(_destinationLabel(widget.operation)),
                prefixIcon: const Icon(Icons.numbers_rounded),
                suffixIcon: widget.operation == PaymentOperation.purchase
                    ? IconButton(
                        tooltip: 'Scan merchant QR code',
                        onPressed: scanQrCode,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      )
                    : null,
              ),
              validator: requiredField,
            ),
            if (widget.operation.requiresAmount) ...[
              const SizedBox(height: 13),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.tr('Amount'),
                  suffixText: 'AFN',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (parsed > AppScope.of(context).dailyLimit ||
                      parsed > AppScope.of(context).monthlyLimit) {
                    return 'Amount exceeds your active transaction limit';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 13),
            if (widget.operation == PaymentOperation.purchase) ...[
              OutlinedButton.icon(
                onPressed: scanQrCode,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(context.tr('Open camera and scan QR code')),
              ),
              const SizedBox(height: 13),
            ],
            TextFormField(
              controller: reference,
              decoration: InputDecoration(
                labelText: context.tr('Reference / note (optional)'),
                prefixIcon: const Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 16),
            const _Notice(),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        context.tr(
                          widget.operation.requiresAmount
                              ? 'Review and submit'
                              : 'Run inquiry',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String? requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  void _selectFundingSource(PaymentFundingSource? selected) {
    if (selected == null) return;
    setState(() {
      fundingSource = selected;
      _syncSource();
    });
  }

  void _syncSource() {
    if (!widget.operation.requiresAmount ||
        fundingSource == PaymentFundingSource.wallet) {
      source.text = WalletIdentity.number;
    } else if (fundingSource == PaymentFundingSource.linkedCard) {
      source.text = LinkedCardStore.card.value ?? '';
    } else {
      source.clear();
    }
  }

  bool _walletCanFund(PaymentOperation operation) => switch (operation) {
    PaymentOperation.walletToCard ||
    PaymentOperation.cardToCard ||
    PaymentOperation.purchase ||
    PaymentOperation.billPayment ||
    PaymentOperation.cashOut => true,
    _ => false,
  };

  Future<void> scanQrCode() async {
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (result == null || !mounted) return;
    final scannedWallet = WalletQrPayload.walletFrom(result);
    if (result.startsWith('payafghan:') && scannedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This PayAfghan QR code is invalid.')),
      );
      return;
    }
    destination.text = scannedWallet ?? result;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Merchant QR code scanned.'))),
    );
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    final now = DateTime.now();
    final request = PaymentRequest(
      operation: widget.operation,
      source: source.text.trim(),
      destination: destination.text.trim(),
      amount: double.tryParse(amount.text) ?? 0,
      reference: reference.text.trim(),
      idempotencyKey: '${widget.operation.code}-${now.microsecondsSinceEpoch}',
    );
    final result = await widget.gateway.execute(request);
    if (!mounted) return;
    setState(() => loading = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xff087f67),
          size: 56,
        ),
        title: Text(result.message, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (request.amount > 0)
              Text(
                afn(request.amount),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const SizedBox(height: 12),
            if (widget.operation == PaymentOperation.billInfo) ...[
              Text(
                '$biller • ${request.destination}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text('${context.tr('Due amount')}: 1,375 AFN'),
              Text('${context.tr('Due date')}: 2026-10-15'),
              Text('${context.tr('Customer')}: Asif Quraishi'),
              const SizedBox(height: 10),
            ],
            Text(
              '${context.tr('Transaction type')}: ${request.operation.code}',
            ),
            Text(
              'Reference: ${result.transactionId}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Mock response — no real funds moved.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final receipt = WalletActivity(
                title: request.operation.label,
                subtitle: request.destination,
                amount: request.amount,
                incoming:
                    request.operation == PaymentOperation.cashIn ||
                    request.operation == PaymentOperation.cardToWallet,
                operation: request.operation,
                date: result.createdAt,
                source: request.source,
                destination: request.destination,
                rrn: result.transactionId.replaceAll('EMI-', ''),
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ReceiptScreen(activity: receipt),
                ),
              );
            },
            child: Text(context.tr('View receipt')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text(context.tr('Done')),
          ),
        ],
      ),
    );
  }

  String _destinationLabel(PaymentOperation operation) => switch (operation) {
    PaymentOperation.billInfo ||
    PaymentOperation.billPayment ||
    PaymentOperation.savePayment => 'Bill / customer number',
    PaymentOperation.purchase => 'Merchant ID or QR reference',
    PaymentOperation.cashIn || PaymentOperation.cashOut => 'Agent ID',
    PaymentOperation.nameInquiry ||
    PaymentOperation.balanceInquiry => 'Account / card / wallet number',
    _ => 'Destination card / wallet / account',
  };
}

class _Notice extends StatelessWidget {
  const _Notice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xfffff4d9),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.security_rounded, color: Color(0xff9a6700)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Prototype mode uses a mock gateway. Production must add strong customer authentication, encryption, sanctions screening, limits, and an immutable audit trail.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
