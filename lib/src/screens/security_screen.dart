import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Security center'))),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _SecurityAction(
          icon: Icons.pin_outlined,
          title: context.tr('Change PIN'),
          subtitle: 'Set a secure 4-digit transaction PIN',
          onTap: () => _showPinDialog(context),
        ),
        const SizedBox(height: 12),
        _SecurityAction(
          icon: Icons.password_rounded,
          title: context.tr('Change password'),
          subtitle: 'Use at least 8 characters, upper/lowercase and a number',
          onTap: () => _showPasswordDialog(context),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(context.tr('Password policy')),
            subtitle: const Text(
              'Minimum 8 characters • uppercase • lowercase • number • password history enabled',
            ),
            isThreeLine: true,
          ),
        ),
      ],
    ),
  );

  Future<void> _showPinDialog(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Change PIN')),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pinField(current, context.tr('Current PIN')),
              const SizedBox(height: 12),
              _pinField(next, context.tr('New PIN')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              _saved(context, 'PIN changed successfully');
            },
            child: Text(context.tr('Save')),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
  }

  TextFormField _pinField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: InputDecoration(labelText: label),
        validator: (value) => value?.length == 4 ? null : 'Enter 4 digits',
      );

  Future<void> _showPasswordDialog(BuildContext context) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Change password')),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('New password'),
                ),
                validator: (value) =>
                    RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$')
                        .hasMatch(value ?? '')
                    ? null
                    : 'Use 8+ characters, upper/lowercase and a number',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirm,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('Confirm password'),
                ),
                validator: (value) =>
                    value == password.text ? null : 'Passwords do not match',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              _saved(context, 'Password changed successfully');
            },
            child: Text(context.tr('Save')),
          ),
        ],
      ),
    );
    password.dispose();
    confirm.dispose();
  }

  void _saved(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _SecurityAction extends StatelessWidget {
  const _SecurityAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
