import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/async_views.dart';
import '../../domain/session_status.dart';
import '../view_models/session.dart';
import 'sign_in_screen.dart';

/// Shows [child] only once the session allows backend calls.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return switch (session) {
      AsyncData(value: SessionStatus.signedIn) => child,
      AsyncData(value: SessionStatus.signedOut) => const SignInScreen(),
      AsyncError() => _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: 'Could not sign in to the PayAfghan server.',
        onRetry: () => ref.read(sessionProvider.notifier).retry(),
      ),
      _ => const Scaffold(body: LoadingView()),
    };
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  if (retry == null)
                    Text(context.tr(message), textAlign: TextAlign.center)
                  else
                    ErrorRetryView(message: message, onRetry: retry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
