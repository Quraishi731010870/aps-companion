/// Whether the app may call authenticated backend endpoints.
enum SessionStatus {
  /// Tokens are stored, or the app runs offline on the mock gateway.
  signedIn,

  /// A backend is configured but there are no tokens and no test user.
  signedOut,
}
