import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/auth_failure.dart';
import '../../domain/phone_number.dart';
import '../view_models/session.dart';
import '../widgets/auth_scaffold.dart';
import 'sign_up_screen.dart';

/// Phone + password sign-in. Debug builds pre-fill the seeded test user from
/// `TEST_USER_PHONE` / `TEST_USER_PASSWORD`; nothing signs in on its own.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  late final AppEnvironment _environment = ref.read(appEnvironmentProvider);
  late final _phone = TextEditingController(
    text: _environment.hasTestUser ? _environment.testUserIdentifier : '',
  );
  late final _password = TextEditingController(
    text: _environment.hasTestUser ? _environment.testUserPassword : '',
  );
  bool _submitting = false;
  AuthFailure? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Sign in to PayAfghan',
    subtitle: 'Use the phone number and password of your wallet.',
    error: _error,
    children: [
      AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                validator: (value) => (value ?? '').isEmpty
                    ? context.tr('Enter your password')
                    : null,
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
                      : Text(context.tr('Sign in')),
                ),
              ),
            ],
          ),
        ),
      ),
      // Open sign-up has no KYC yet, so release builds don't offer it.
      if (!_environment.isRelease) ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
                ),
          child: Text(context.tr('New here? Create an account')),
        ),
      ],
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
          .signIn(identifier: phone, password: _password.text);
    } on AuthFailure catch (failure) {
      _fail(failure);
    } on FormatException {
      _fail(AuthFailure.unknown);
    }
  }

  void _fail(AuthFailure failure) {
    if (!mounted) return;
    _password.clear();
    setState(() {
      _submitting = false;
      _error = failure;
    });
  }
}
