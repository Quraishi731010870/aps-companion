import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/payment_gateway_provider.dart';
import '../../domain/wallet.dart';

part 'wallet.g.dart';

/// The customer's wallet (id and balance). Invalidated after each payment.
@riverpod
Future<Wallet> wallet(Ref ref) =>
    ref.watch(paymentGatewayProvider).fetchWallet();
