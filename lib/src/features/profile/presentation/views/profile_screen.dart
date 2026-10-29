import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../admin/presentation/views/google_sheets_screen.dart';
import '../../../admin/presentation/views/management_screen.dart';
import '../../../../core/config/app_environment.dart';
import '../../../auth/presentation/view_models/current_user.dart';
import '../../../auth/presentation/view_models/session.dart';
import '../../../settings/domain/biometric_outcome.dart';
import '../../../settings/presentation/view_models/settings.dart';
import '../../../settings/presentation/views/limits_screen.dart';
import '../../../payments/presentation/view_models/wallet.dart';
import 'security_screen.dart';
import 'wallet_qr_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricEnabled = ref.watch(
      settingsProvider.select((settings) => settings.biometricEnabled),
    );
    final languageCode = ref.watch(
      settingsProvider.select((settings) => settings.languageCode),
    );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            context.tr('Profile'),
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          const _ProfileCard(),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_2_rounded),
              title: const Text(
                'My wallet QR',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(switch (ref.watch(walletProvider)) {
                AsyncData(:final value) => 'Receive to wallet ${value.masked}',
                AsyncError() => context.tr('Wallet unavailable'),
                _ => context.tr('Loading wallet…'),
              }),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletQrScreen())),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfffff4da),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xff955f00)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic KYC verification',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'ID, selfie and sanctions screening pending',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Label(context.tr('Security & compliance')),
          Card(
            child: Column(
              children: [
                _Setting(
                  Icons.badge_outlined,
                  context.tr('Identity verification'),
                  context.tr('KYC tier, limits and source of funds'),
                ),
                const Divider(height: 1, indent: 64),
                _Setting(
                  Icons.lock_outline_rounded,
                  context.tr('PIN & password'),
                  context.tr('Credentials and recovery'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: Text(
                    context.tr('Biometric login'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    context.tr('Fingerprint or face authentication'),
                  ),
                  value: biometricEnabled,
                  onChanged: (value) => _setBiometric(context, ref, value),
                ),
                const Divider(height: 1, indent: 64),
                _Setting(
                  Icons.devices_outlined,
                  context.tr('Trusted devices'),
                  context.tr('Sessions and device binding'),
                ),
                const Divider(height: 1, indent: 64),
                _Setting(
                  Icons.speed_outlined,
                  context.tr('Transaction limits'),
                  context.tr('Daily and monthly controls'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LimitsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Label(context.tr('Preferences & support')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(
                    context.tr('Language'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(languageCode == 'fa' ? 'دری' : 'English'),
                  trailing: DropdownButton<String>(
                    underline: const SizedBox(),
                    value: languageCode,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('EN')),
                      DropdownMenuItem(value: 'fa', child: Text('دری')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      ref.read(settingsProvider.notifier).setLanguage(value);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 64),
                _Setting(
                  Icons.location_on_outlined,
                  context.tr('Agent locations'),
                  context.tr('Cash-in and cash-out points'),
                ),
                const Divider(height: 1, indent: 64),
                _Setting(
                  Icons.help_outline_rounded,
                  context.tr('Help & disputes'),
                  context.tr('Support, fraud reports and FAQs'),
                ),
                const Divider(height: 1, indent: 64),
                _Setting(
                  Icons.gavel_outlined,
                  context.tr('Legal, fees & privacy'),
                  context.tr('Policies and consent records'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Label(context.tr('Platform management')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text(
                    'Google Sheets',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('View and add Users worksheet rows'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GoogleSheetsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 64),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(
                    context.tr('Platform management'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    context.tr('SVRB configuration and operations'),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManagementScreen()),
                  ),
                ),
              ],
            ),
          ),
          if (ref.watch(
            appEnvironmentProvider.select((e) => e.hasBackend),
          )) ...[
            const SizedBox(height: 14),
            const _SignOutTile(),
          ],
          const SizedBox(height: 14),
          Center(
            child: Text(
              context.tr('Development prototype • No real funds'),
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setBiometric(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final settings = ref.read(settingsProvider.notifier);
    if (!enable) {
      settings.disableBiometric();
      return;
    }
    final outcome = await settings.enableBiometric(
      context.tr('Verify your identity to enable biometric login'),
    );
    if (!context.mounted) return;
    final message = switch (outcome) {
      BiometricOutcome.verified => null,
      BiometricOutcome.cancelled => null,
      BiometricOutcome.unavailable =>
        'Biometric authentication is not available on this device.',
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(message))));
  }
}

class _SignOutTile extends ConsumerStatefulWidget {
  const _SignOutTile();

  @override
  ConsumerState<_SignOutTile> createState() => _SignOutTileState();
}

class _SignOutTileState extends ConsumerState<_SignOutTile> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Card(
      child: ListTile(
        enabled: !_signingOut,
        leading: Icon(Icons.logout_rounded, color: error),
        title: Text(
          context.tr('Sign out'),
          style: TextStyle(color: error, fontWeight: FontWeight.w800),
        ),
        onTap: () async {
          setState(() => _signingOut = true);
          // The session gate swaps to the sign-in screen once this completes.
          await ref.read(sessionProvider.notifier).signOut();
        },
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(displayedUserProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 31,
              backgroundColor: const Color(0xffd9efe9),
              child: Text(
                user.initials,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Colors.black54,
      ),
    ),
  );
}

class _Setting extends StatelessWidget {
  const _Setting(this.icon, this.title, this.subtitle, {this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
