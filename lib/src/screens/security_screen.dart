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

  Future<void> _showPinDialog(BuildContext context) {
    String? pin(String value, String _) =>
        value.length == 4 ? null : 'Enter 4 digits';
    final pinFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ];
    return _change(
      context,
      _TwoFieldDialog(
        title: 'Change PIN',
        first: (
          label: 'Current PIN',
          keyboard: TextInputType.number,
          formatters: pinFormatters,
          validator: pin,
        ),
        second: (
          label: 'New PIN',
          keyboard: TextInputType.number,
          formatters: pinFormatters,
          validator: pin,
        ),
      ),
      'PIN changed successfully',
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) => _change(
    context,
    _TwoFieldDialog(
      title: 'Change password',
      first: (
        label: 'New password',
        keyboard: TextInputType.visiblePassword,
        formatters: const [],
        validator: (value, _) =>
            RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(value)
            ? null
            : 'Use 8+ characters, upper/lowercase and a number',
      ),
      second: (
        label: 'Confirm password',
        keyboard: TextInputType.visiblePassword,
        formatters: const [],
        validator: (value, first) =>
            value == first ? null : 'Passwords do not match',
      ),
    ),
    'Password changed successfully',
  );

  Future<void> _change(
    BuildContext context,
    _TwoFieldDialog dialog,
    String successMessage,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => dialog,
    );
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(successMessage))));
  }
}

typedef _FieldSpec = ({
  String label,
  TextInputType keyboard,
  List<TextInputFormatter> formatters,

  /// Receives this field's value and the first field's value.
  String? Function(String value, String first) validator,
});

/// Obscured two-field form used for PIN and password changes. Owns its
/// controllers so they are disposed only after the dialog route is gone.
class _TwoFieldDialog extends StatefulWidget {
  const _TwoFieldDialog({
    required this.title,
    required this.first,
    required this.second,
  });
  final String title;
  final _FieldSpec first;
  final _FieldSpec second;

  @override
  State<_TwoFieldDialog> createState() => _TwoFieldDialogState();
}

class _TwoFieldDialogState extends State<_TwoFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(widget.title)),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ObscuredField(_first, widget.first, matches: _first),
          const SizedBox(height: 12),
          _ObscuredField(_second, widget.second, matches: _first),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, true);
        },
        child: Text(context.tr('Save')),
      ),
    ],
  );
}

class _ObscuredField extends StatelessWidget {
  const _ObscuredField(this.controller, this.spec, {required this.matches});
  final TextEditingController controller;
  final _FieldSpec spec;

  /// The first field, passed to [spec]'s validator for confirmation checks.
  final TextEditingController matches;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: true,
    keyboardType: spec.keyboard,
    inputFormatters: spec.formatters,
    decoration: InputDecoration(labelText: context.tr(spec.label)),
    validator: (value) => spec.validator(value ?? '', matches.text),
  );
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
