import 'package:flutter/foundation.dart';

/// The signed-in customer, kept in secure storage. Deliberately minimal (APS
/// p.40, privacy by design): no phone number, roles or permissions.
@immutable
class UserProfile {
  const UserProfile({required this.id, required this.displayName});

  /// Shown when no account is signed in (offline mock mode).
  static const demo = UserProfile(id: 'demo', displayName: 'Asif Quraishi');

  final String id;
  final String displayName;

  /// Up to two initials for avatars, e.g. "Demo Customer 001" → "DC".
  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'));
    final letters = [
      for (final word in words.take(2))
        if (word.isNotEmpty) word[0].toUpperCase(),
    ].join();
    return letters.isEmpty ? '?' : letters;
  }

  Map<String, String> toJson() => {'id': id, 'displayName': displayName};

  /// Returns null for anything that is not a complete stored profile.
  static UserProfile? fromJson(Object? json) => switch (json) {
    {'id': final String id, 'displayName': final String name}
        when id.isNotEmpty =>
      UserProfile(id: id, displayName: name),
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, displayName);
}
