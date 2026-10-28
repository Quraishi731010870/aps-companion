import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/remote_config/state/mobile_config.dart';
import '../../domain/payment_transaction.dart';

part 'enabled_operations.g.dart';

/// Operations the remote feature flags allow, in display order.
@riverpod
List<PaymentOperation> enabledOperations(Ref ref) {
  final config = ref.watch(currentConfigProvider);
  return [
    for (final operation in PaymentOperation.values)
      if (config.featureEnabled(operation.configurationKey, safeDefault: true))
        operation,
  ];
}
