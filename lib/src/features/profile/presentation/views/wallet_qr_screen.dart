import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/widgets/async_views.dart';
import '../../../payments/domain/wallet.dart';
import '../../../payments/presentation/view_models/wallet.dart';
import '../../domain/wallet_qr_payload.dart';

class WalletQrScreen extends ConsumerWidget {
  const WalletQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('My wallet QR')),
    body: switch (ref.watch(walletProvider)) {
      AsyncData(:final value) => _WalletQr(value),
      AsyncError() => ErrorRetryView(
        message: 'Your wallet could not be loaded.',
        onRetry: () => ref.invalidate(walletProvider),
      ),
      _ => const LoadingView(),
    },
  );
}

class _WalletQr extends StatelessWidget {
  const _WalletQr(this.wallet);
  final Wallet wallet;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 42,
                color: Color(0xff087f67),
              ),
              const SizedBox(height: 10),
              const Text(
                'Receive to your wallet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('Wallet ${wallet.masked}'),
              const SizedBox(height: 18),
              QrImageView(
                data: WalletQrPayload.forWallet(wallet.id).toString(),
                size: 248,
                backgroundColor: Colors.white,
                errorStateBuilder: (context, error) => const SizedBox(
                  width: 248,
                  height: 248,
                  child: Center(child: Text('Could not create wallet QR.')),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(wallet.id),
              const SizedBox(height: 18),
              const Text(
                'Demo receive code only. A payment cannot be completed until a real wallet/payment backend is connected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
