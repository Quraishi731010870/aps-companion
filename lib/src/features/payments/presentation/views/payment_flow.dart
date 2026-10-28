import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/currency_format.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../profile/domain/wallet_identity.dart';
import '../../../settings/presentation/view_models/settings.dart';
import '../../domain/card_number.dart';
import '../../domain/payment_transaction.dart';
import '../view_models/linked_card.dart';
import '../view_models/payment_submission.dart';
import '../widgets/transaction_state_style.dart';
import 'qr_scanner_screen.dart';
import 'receipt_screen.dart';

Future<void> openPaymentFlow(
  BuildContext context,
  PaymentOperation operation, {
  bool scanQrOnOpen = false,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) =>
        PaymentFlowScreen(operation: operation, scanQrOnOpen: scanQrOnOpen),
  ),
);

enum PaymentFundingSource { wallet, linkedCard, manualCard }

class PaymentFlowScreen extends ConsumerStatefulWidget {
  const PaymentFlowScreen({
    super.key,
    required this.operation,
    this.scanQrOnOpen = false,
  });
  final PaymentOperation operation;
  final bool scanQrOnOpen;

  @override
  ConsumerState<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends ConsumerState<PaymentFlowScreen> {
  final formKey = GlobalKey<FormState>();
  final source = TextEditingController();
  final destination = TextEditingController();
  final amount = TextEditingController();
  final reference = TextEditingController();
  late PaymentFundingSource fundingSource;
  String biller = 'DABS Electricity';

  @override
  void initState() {
    super.initState();
    fundingSource = _walletCanFund(widget.operation)
        ? PaymentFundingSource.wallet
        : ref.read(linkedCardProvider) == null
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
  Widget build(BuildContext context) {
    ref.listen(paymentSubmissionProvider, _onSubmissionChanged);
    final loading = ref.watch(
      paymentSubmissionProvider.select((submission) => submission.isLoading),
    );
    final linkedCard = ref.watch(linkedCardProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.operation.label)),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _OperationHeader(widget.operation),
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
                        if (_walletCanFund(widget.operation)) ...[
                          RadioListTile<PaymentFundingSource>(
                            value: PaymentFundingSource.wallet,
                            secondary: const Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            title: Text(
                              context.tr('Use wallet number as a card'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'PayAfghan wallet ${WalletIdentity.masked}',
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                        ],
                        RadioListTile<PaymentFundingSource>(
                          value: PaymentFundingSource.linkedCard,
                          enabled: linkedCard != null,
                          secondary: const Icon(Icons.link_rounded),
                          title: Text(
                            context.tr('Use linked card'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            linkedCard ??
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
                  validator: (value) => CardNumber.isValid(value ?? '')
                      ? null
                      : 'Enter a valid card number',
                ),
              ],
              const SizedBox(height: 13),
              if (_isBill(widget.operation)) ...[
                DropdownButtonFormField<String>(
                  initialValue: biller,
                  decoration: InputDecoration(
                    labelText: context.tr('Biller'),
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                  items: [
                    for (final name in _billers)
                      DropdownMenuItem(value: name, child: Text(name)),
                  ],
                  onChanged: (value) => biller = value ?? biller,
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
                validator: _requiredField,
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
                  validator: _validateAmount,
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
                  onPressed: loading ? null : _submit,
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
  }

  static const _billers = [
    'DABS Electricity',
    'AUWSSC Water',
    'Afghan Telecom',
    'Municipality',
  ];

  static String? _requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validateAmount(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
    if (!ref.read(settingsProvider).limits.allows(parsed)) {
      return 'Amount exceeds your active transaction limit';
    }
    return null;
  }

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
      source.text = ref.read(linkedCardProvider) ?? '';
    } else {
      source.clear();
    }
  }

  static bool _isBill(PaymentOperation operation) => switch (operation) {
    PaymentOperation.billInfo ||
    PaymentOperation.billPayment ||
    PaymentOperation.savePayment => true,
    _ => false,
  };

  static bool _walletCanFund(PaymentOperation operation) => switch (operation) {
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
      _showMessage('This PayAfghan QR code is invalid.');
      return;
    }
    destination.text = scannedWallet ?? result;
    _showMessage('Merchant QR code scanned.');
  }

  void _submit() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    ref
        .read(paymentSubmissionProvider.notifier)
        .submit(
          operation: widget.operation,
          source: source.text.trim(),
          destination: destination.text.trim(),
          amount: double.tryParse(amount.text) ?? 0,
          reference: reference.text.trim(),
        );
  }

  void _onSubmissionChanged(
    AsyncValue<PaymentResult?>? previous,
    AsyncValue<PaymentResult?> next,
  ) {
    if (previous?.isLoading != true) return;
    switch (next) {
      case AsyncData(:final value?):
        _showResult(value);
      case AsyncError():
        _showMessage('The payment could not be completed. Please try again.');
      default:
        break;
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(message))));

  Future<void> _showResult(PaymentResult result) async {
    final action = await showDialog<_ResultAction>(
      context: context,
      builder: (_) => _PaymentResultDialog(result: result, biller: biller),
    );
    if (!mounted) return;
    final navigator = Navigator.of(context);
    switch (action) {
      case _ResultAction.viewReceipt:
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(activity: _receiptFor(result)),
          ),
        );
      case _ResultAction.done:
        navigator.pop();
      case null:
        break;
    }
  }

  static WalletActivity _receiptFor(PaymentResult result) {
    final request = result.request;
    return WalletActivity(
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
      status: result.state,
    );
  }

  static String _destinationLabel(PaymentOperation operation) =>
      switch (operation) {
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

class _OperationHeader extends StatelessWidget {
  const _OperationHeader(this.operation);
  final PaymentOperation operation;

  @override
  Widget build(BuildContext context) => Container(
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
          child: Icon(operation.icon, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(operation.label),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Transaction type ${operation.code}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

enum _ResultAction { viewReceipt, done }

class _PaymentResultDialog extends StatelessWidget {
  const _PaymentResultDialog({required this.result, required this.biller});
  final PaymentResult result;
  final String biller;

  @override
  Widget build(BuildContext context) {
    final request = result.request;
    return AlertDialog(
      icon: Icon(
        result.state.icon,
        color: result.state.color(Theme.of(context).colorScheme),
        size: 56,
      ),
      title: Text(result.message, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (request.amount > 0)
            Text(
              afn(request.amount),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
          Text(context.tr(result.state.label)),
          const SizedBox(height: 12),
          if (request.operation == PaymentOperation.billInfo) ...[
            Text(
              '$biller • ${request.destination}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('${context.tr('Due amount')}: 1,375 AFN'),
            Text('${context.tr('Due date')}: 2026-10-15'),
            Text('${context.tr('Customer')}: Asif Quraishi'),
            const SizedBox(height: 10),
          ],
          Text('${context.tr('Transaction type')}: ${request.operation.code}'),
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
          onPressed: () => Navigator.pop(context, _ResultAction.viewReceipt),
          child: Text(context.tr('View receipt')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ResultAction.done),
          child: Text(context.tr('Done')),
        ),
      ],
    );
  }
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
