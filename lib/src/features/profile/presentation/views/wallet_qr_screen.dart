import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/wallet_identity.dart';

class WalletQrScreen extends StatelessWidget {
  const WalletQrScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My wallet QR')),
    body: Center(
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
                Text('Wallet ${WalletIdentity.masked}'),
                const SizedBox(height: 18),
                QrImageView(
                  data: WalletQrPayload.forWallet(WalletIdentity.number)
                      .toString(),
                  size: 248,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) => const SizedBox(
                    width: 248,
                    height: 248,
                    child: Center(child: Text('Could not create wallet QR.')),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(WalletIdentity.number),
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
    ),
  );
}
