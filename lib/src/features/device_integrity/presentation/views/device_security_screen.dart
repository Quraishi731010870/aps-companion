import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/async_views.dart';
import '../../../developer/presentation/views/developer_mode_screen.dart';
import '../../domain/device_integrity_report.dart';
import '../../domain/integrity_signal.dart';
import '../view_models/device_integrity.dart';
import '../widgets/integrity_style.dart';

/// Settings → Device security: every check, its result and the policy.
class DeviceSecurityScreen extends ConsumerWidget {
  const DeviceSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(deviceIntegrityProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Device security'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: switch (report) {
              AsyncValue(value: final DeviceIntegrityReport value) =>
                _ReportView(report: value, refreshing: report.isLoading),
              AsyncValue(error: _?) => ErrorRetryView(
                message: 'The device checks could not run.',
                onRetry: () =>
                    ref.read(deviceIntegrityProvider.notifier).recheck(),
              ),
              _ => const LoadingView(),
            },
          ),
        ),
      ),
    );
  }
}

class _ReportView extends ConsumerWidget {
  const _ReportView({required this.report, required this.refreshing});
  final DeviceIntegrityReport report;
  final bool refreshing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(integrityStatusProvider);
    final isRelease = ref.watch(
      appEnvironmentProvider.select((environment) => environment.isRelease),
    );
    final checks = [
      ...report.applicableChecks,
      for (final signal in status.simulated)
        if (!report.applicableChecks.contains(signal)) signal,
    ];
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(report.checkedAt));
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _Summary(status: status),
        const SizedBox(height: 18),
        if (!report.supported)
          EmptyView(
            icon: Icons.phonelink_off_rounded,
            message: 'Device checks run only on Android and iOS.',
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, signal) in checks.indexed) ...[
                  if (index > 0) const Divider(height: 1, indent: 64),
                  _CheckTile(
                    signal: signal,
                    detected: status.detected.contains(signal),
                    simulated: status.simulated.contains(signal),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '${context.tr('Last checked')} $time',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: refreshing
              ? null
              : () => ref.read(deviceIntegrityProvider.notifier).recheck(),
          icon: refreshing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          label: Text(context.tr('Check again')),
        ),
        if (!isRelease) ...[
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.developer_mode_rounded),
              title: Text(
                context.tr('Developer mode'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(context.tr('Enforce or simulate detections')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeveloperModeScreen()),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.status});
  final IntegrityStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show what the policy says even when a debug build does not enforce it.
    final verdict = status.risk.verdict;
    final color = status.risk.color(theme.colorScheme);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(verdict.icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(verdict.title),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.tr(verdict.detail)),
            if (!status.enforced && verdict != IntegrityVerdict.allow) ...[
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Debug build: nothing is blocked. Release builds enforce '
                  'this policy.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.signal,
    required this.detected,
    required this.simulated,
  });
  final IntegritySignal signal;
  final bool detected;
  final bool simulated;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final found = detected || simulated;
    final status = switch ((detected, simulated)) {
      (true, _) => 'Detected',
      (false, true) => 'Simulated',
      _ => 'Not detected',
    };
    return ListTile(
      leading: Icon(
        found ? Icons.error_outline_rounded : Icons.check_circle_outline,
        color: found ? signal.risk.color(colors) : colors.primary,
      ),
      title: Text(
        context.tr(signal.label),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        found
            ? '${context.tr(signal.description)}\n'
                  '${context.tr(status)} • ${context.tr(signal.risk.label)}'
            : context.tr(status),
      ),
      isThreeLine: found,
    );
  }
}
