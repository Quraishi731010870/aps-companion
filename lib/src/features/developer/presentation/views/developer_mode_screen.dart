import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/remote_config/state/mobile_config.dart';
import '../../../auth/presentation/view_models/current_user.dart';
import '../../../auth/domain/session_status.dart';
import '../../../auth/presentation/view_models/session.dart';
import '../../../device_integrity/domain/integrity_signal.dart';
import '../../../device_integrity/presentation/view_models/device_integrity.dart';
import '../../../device_integrity/presentation/views/device_security_screen.dart';
import '../../../device_integrity/presentation/widgets/integrity_style.dart';
import '../../../settings/presentation/view_models/settings.dart';

/// Debug and profile builds only: integrity overrides plus a read-out of the
/// app's build, configuration, session and settings. Never shows secrets.
class DeveloperModeScreen extends ConsumerWidget {
  const DeveloperModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRelease = ref.watch(
      appEnvironmentProvider.select((environment) => environment.isRelease),
    );
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Developer mode'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: isRelease
                ? Center(
                    child: Text(
                      context.tr('Developer mode is off in release builds.'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: const [
                      _Section('Integrity policy'),
                      _PolicyCard(),
                      _Section('Simulate detections'),
                      _SimulationCard(),
                      _Section('Build and environment'),
                      _EnvironmentCard(),
                      _Section('Session'),
                      _SessionCard(),
                      _Section('App settings'),
                      _SettingsCard(),
                      _Section('Remote configuration'),
                      _RemoteConfigCard(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PolicyCard extends ConsumerWidget {
  const _PolicyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enforce = ref.watch(
      integrityOverridesControllerProvider.select((o) => o.enforce),
    );
    final status = ref.watch(integrityStatusProvider);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.policy_outlined),
            title: const Text(
              'Enforce in this build',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Off: checks are only reported. Release builds always enforce.',
            ),
            value: enforce,
            onChanged: (value) => ref
                .read(integrityOverridesControllerProvider.notifier)
                .setEnforced(value),
          ),
          const Divider(height: 1, indent: 64),
          _Row('Risk', status.risk.label),
          _Row('Verdict now', status.verdict.name),
          _Row(
            'Detected',
            status.detected.isEmpty
                ? 'none'
                : status.detected.map((s) => s.name).join(', '),
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded),
            title: const Text('Live device checks'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DeviceSecurityScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationCard extends ConsumerWidget {
  const _SimulationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulated = ref.watch(
      integrityOverridesControllerProvider.select((o) => o.simulated),
    );
    final controller = ref.read(integrityOverridesControllerProvider.notifier);
    return Card(
      child: Column(
        children: [
          for (final signal in IntegritySignal.values)
            CheckboxListTile(
              value: simulated.contains(signal),
              onChanged: (value) =>
                  controller.setSimulated(signal, value ?? false),
              title: Text(signal.label),
              subtitle: Text(signal.risk.label),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: const Text('Reset developer overrides'),
            onTap: controller.reset,
          ),
        ],
      ),
    );
  }
}

class _EnvironmentCard extends ConsumerWidget {
  const _EnvironmentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);
    final backend = Uri.tryParse(environment.apiBaseUrl);
    return Card(
      child: Column(
        children: [
          _Row('Build mode', kProfileMode ? 'profile' : 'debug'),
          _Row('Platform', kIsWeb ? 'web' : defaultTargetPlatform.name),
          _Row(
            'Backend',
            environment.hasBackend && backend != null
                ? backend.origin
                : 'offline mock',
          ),
          _Row('Test user', _yesNo(environment.hasTestUser)),
          _Row('Card key pinned', _yesNo(environment.cardKeySha256.isNotEmpty)),
          _Row('Google Sheets', _yesNo(environment.hasSheets)),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = ref.watch(currentUserProvider);
    return Card(
      child: Column(
        children: [
          _Row('Session', switch (session) {
            AsyncValue(value: final SessionStatus value) => value.name,
            AsyncValue(error: _?) => 'error',
            _ => 'loading',
          }),
          _Row('User', switch (user) {
            AsyncValue(hasValue: true, :final value) =>
              value?.displayName ?? 'none',
            AsyncValue(error: _?) => 'error',
            _ => 'loading',
          }),
        ],
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final limits = settings.limits;
    return Card(
      child: Column(
        children: [
          _Row('Language', settings.languageCode),
          _Row('Biometric login', _yesNo(settings.biometricEnabled)),
          _Row('Daily limit', '${limits.daily.toStringAsFixed(0)} AFN'),
          _Row('Monthly limit', '${limits.monthly.toStringAsFixed(0)} AFN'),
          _Row('Daily count', '${limits.dailyCount}'),
        ],
      ),
    );
  }
}

class _RemoteConfigCard extends ConsumerWidget {
  const _RemoteConfigCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(currentConfigProvider);
    final features = config.features.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Card(
      child: Column(
        children: [
          _Row('Version', '${config.version}'),
          _Row('From cache', _yesNo(config.fromCache)),
          _Row('Maintenance mode', _yesNo(config.maintenanceMode)),
          for (final MapEntry(:key, :value) in features)
            _Row(key, value ? 'on' : 'off'),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: const Text('Reload configuration'),
            onTap: () => ref.read(mobileConfigProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}

String _yesNo(bool value) => value ? 'yes' : 'no';

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 18, bottom: 9),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Text(
        value,
        textAlign: TextAlign.end,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
