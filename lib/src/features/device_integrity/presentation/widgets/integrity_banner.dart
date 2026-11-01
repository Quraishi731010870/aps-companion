import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/integrity_signal.dart';
import '../view_models/device_integrity.dart';
import '../views/device_security_screen.dart';
import 'integrity_style.dart';

/// Warns when the device is risky or payments are blocked; otherwise empty.
class IntegrityBanner extends ConsumerWidget {
  const IntegrityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verdict = ref.watch(
      integrityStatusProvider.select((status) => status.verdict),
    );
    if (verdict == IntegrityVerdict.allow ||
        verdict == IntegrityVerdict.blockApp) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final blocked = verdict == IntegrityVerdict.blockPayments;
    final foreground = blocked
        ? colors.onErrorContainer
        : colors.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: Material(
        color: blocked ? colors.errorContainer : colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          iconColor: foreground,
          textColor: foreground,
          leading: Icon(verdict.icon),
          title: Text(
            context.tr(verdict.title),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(context.tr('Tap to see what was found')),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeviceSecurityScreen()),
          ),
        ),
      ),
    );
  }
}
