import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../payments/data/payment_gateway_provider.dart';
import '../../../payments/domain/payment_transaction.dart';

part 'activities.g.dart';

/// Wallet history from the active gateway. Invalidated after each payment.
@riverpod
Future<List<WalletActivity>> activities(Ref ref) =>
    ref.watch(paymentGatewayProvider).fetchActivities();
