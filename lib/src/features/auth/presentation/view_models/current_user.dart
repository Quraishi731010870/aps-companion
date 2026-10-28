import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_environment.dart';
import '../../data/auth_repository.dart';
import '../../domain/session_status.dart';
import '../../domain/user_profile.dart';
import 'session.dart';

part 'current_user.g.dart';

/// The signed-in user from secure storage; reloads after each sign-in.
/// Null in offline mock mode or when signed out.
@Riverpod(keepAlive: true)
Future<UserProfile?> currentUser(Ref ref) async {
  if (!ref.watch(appEnvironmentProvider).hasBackend) return null;
  final status = await ref.watch(sessionProvider.future);
  if (status != SessionStatus.signedIn) return null;
  return ref.watch(authRepositoryProvider).currentUser();
}

/// The user to show in the UI: the signed-in user, otherwise the demo user.
@riverpod
UserProfile displayedUser(Ref ref) =>
    ref.watch(currentUserProvider).value ?? UserProfile.demo;
