import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/auth_failure.dart';
import '../../domain/phone_number.dart';
import '../view_models/session.dart';
import '../widgets/auth_scaffold.dart';

/// Development sign-up: creates a customer with an empty wallet and signs in.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  AuthFailure? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    showBack: true,
    title: 'Create your account',
    subtitle: 'For testing: a new customer with an empty AFN wallet.',
    error: _error,
    children: [
      AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('Full name'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => (value ?? '').trim().length < 2
                    ? context.tr('Enter your name')
                    : null,
              ),
              const SizedBox(height: 14),
              PhoneField(
                controller: _phone,
                validator: (value) => PhoneNumber.normalize(value ?? '') == null
                    ? context.tr('Enter an Afghan mobile number')
                    : null,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _password,
                label: 'Password',
                newPassword: true,
                validator: (value) => PasswordRules.isValid(value ?? '')
                    ? null
                    : context.tr('Use at least 10 characters'),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirm,
                label: 'Confirm password',
                newPassword: true,
                validator: (value) => value == _password.text
                    ? null
                    : context.tr('Passwords do not match'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('Create account')),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _submit() async {
    if (_submitting || !(_form.currentState?.validate() ?? false)) return;
    final phone = PhoneNumber.normalize(_phone.text);
    if (phone == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .register(
            displayName: _name.text.trim(),
            phone: phone,
            password: _password.text,
          );
      // Signed in: the session gate behind this route now shows the app.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (failure) {
      _fail(failure);
    } on FormatException {
      _fail(AuthFailure.unknown);
    }
  }

  void _fail(AuthFailure failure) {
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = failure;
    });
  }
}
