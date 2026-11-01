import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../developer/presentation/views/developer_mode_screen.dart';
import '../../domain/integrity_signal.dart';
import '../view_models/device_integrity.dart';
import '../widgets/integrity_style.dart';

/// Replaces the whole app when the device is high risk (APS p.44).
class DeviceBlockedScreen extends ConsumerWidget {
  const DeviceBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signals = [
      for (final signal in ref.watch(integrityStatusProvider).signals)
        if (signal.risk == IntegrityRisk.high) signal,
    ];
    final checking = ref.watch(
      deviceIntegrityProvider.select((report) => report.isLoading),
    );
    final isRelease = ref.watch(
      appEnvironmentProvider.select((environment) => environment.isRelease),
    );
    final theme = Theme.of(context);
    const verdict = IntegrityVerdict.blockApp;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(32),
              children: [
                Icon(verdict.icon, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 20),
                Text(
                  context.tr(verdict.title),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.tr(verdict.detail), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                for (final signal in signals)
                  Text(
                    '• ${context.tr(signal.label)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Use PayAfghan on an unmodified phone, or contact support.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: checking
                      ? null
                      : () => ref
                            .read(deviceIntegrityProvider.notifier)
                            .recheck(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('Check again')),
                ),
                if (!isRelease) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeveloperModeScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.developer_mode_rounded),
                    label: Text(context.tr('Developer mode')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
