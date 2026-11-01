import 'package:flutter/material.dart';

import '../../domain/integrity_signal.dart';

/// Display text and colours for risk levels and verdicts, in one place.
extension IntegrityRiskStyle on IntegrityRisk {
  String get label => switch (this) {
    IntegrityRisk.none => 'No risk',
    IntegrityRisk.low => 'Low risk',
    IntegrityRisk.medium => 'Medium risk',
    IntegrityRisk.high => 'High risk',
  };

  Color color(ColorScheme colors) => switch (this) {
    IntegrityRisk.none => colors.primary,
    IntegrityRisk.low => colors.tertiary,
    IntegrityRisk.medium || IntegrityRisk.high => colors.error,
  };
}

extension IntegrityVerdictStyle on IntegrityVerdict {
  String get title => switch (this) {
    IntegrityVerdict.allow => 'This device passed the security checks',
    IntegrityVerdict.warn => 'Security warning',
    IntegrityVerdict.blockPayments => 'Payments are turned off on this device',
    IntegrityVerdict.blockApp => 'This device cannot be used',
  };

  String get detail => switch (this) {
    IntegrityVerdict.allow => 'No root, jailbreak or tampering was found.',
    IntegrityVerdict.warn =>
      'Some settings on this device make it less safe. You can keep using '
          'PayAfghan.',
    IntegrityVerdict.blockPayments =>
      'You can still see your balance and history, but sending money is '
          'blocked to protect your account.',
    IntegrityVerdict.blockApp =>
      'This device has been changed in a way that puts your money at risk, '
          'such as root or jailbreak.',
  };

  IconData get icon => switch (this) {
    IntegrityVerdict.allow => Icons.verified_user_outlined,
    IntegrityVerdict.warn => Icons.gpp_maybe_outlined,
    IntegrityVerdict.blockPayments => Icons.gpp_bad_outlined,
    IntegrityVerdict.blockApp => Icons.block_rounded,
  };
}
