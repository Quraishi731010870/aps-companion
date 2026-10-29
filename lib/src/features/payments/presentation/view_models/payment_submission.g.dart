// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_submission.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ViewModel for submitting one payment. `null` data means nothing submitted
/// yet; errors surface as [AsyncError] for the view to report.

@ProviderFor(PaymentSubmission)
final paymentSubmissionProvider = PaymentSubmissionProvider._();

/// ViewModel for submitting one payment. `null` data means nothing submitted
/// yet; errors surface as [AsyncError] for the view to report.
final class PaymentSubmissionProvider
    extends $AsyncNotifierProvider<PaymentSubmission, PaymentResult?> {
  /// ViewModel for submitting one payment. `null` data means nothing submitted
  /// yet; errors surface as [AsyncError] for the view to report.
  PaymentSubmissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentSubmissionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentSubmissionHash();

  @$internal
  @override
  PaymentSubmission create() => PaymentSubmission();
}

String _$paymentSubmissionHash() => r'd22ebf9653a00e7e3aad9910c507b8cf47f0d3b5';

/// ViewModel for submitting one payment. `null` data means nothing submitted
/// yet; errors surface as [AsyncError] for the view to report.

abstract class _$PaymentSubmission extends $AsyncNotifier<PaymentResult?> {
  FutureOr<PaymentResult?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PaymentResult?>, PaymentResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PaymentResult?>, PaymentResult?>,
              AsyncValue<PaymentResult?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
