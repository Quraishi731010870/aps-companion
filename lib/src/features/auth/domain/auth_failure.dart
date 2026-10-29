/// Why sign-in or sign-up failed, as far as the user needs to know.
enum AuthFailure implements Exception {
  invalidCredentials('The phone number or password is incorrect.'),
  accountLocked('Too many attempts. Try again in 15 minutes.'),
  phoneInUse('This phone number is already registered. Sign in instead.'),
  registrationClosed('Sign-up is not available.'),
  notAllowed('This account cannot sign in to the mobile app.'),
  network('Could not reach the PayAfghan server. Check your connection.'),
  unknown('Something went wrong. Please try again.');

  const AuthFailure(this.message);

  /// English text; translate with `context.tr`.
  final String message;

  @override
  String toString() => message;
}
