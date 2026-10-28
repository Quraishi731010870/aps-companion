import 'dart:convert';

import 'package:afghan_emi/src/features/auth/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserProfile(id: 'user-1', displayName: 'Demo Customer 001');

  test('round-trips through JSON', () {
    final decoded = UserProfile.fromJson(jsonDecode(jsonEncode(user.toJson())));
    expect(decoded, user);
  });

  test('stores only the id and display name', () {
    expect(user.toJson().keys, unorderedEquals(['id', 'displayName']));
  });

  test('rejects incomplete or malformed stored values', () {
    expect(UserProfile.fromJson(null), isNull);
    expect(UserProfile.fromJson('text'), isNull);
    expect(UserProfile.fromJson({'id': 'user-1'}), isNull);
    expect(UserProfile.fromJson({'id': '', 'displayName': 'X'}), isNull);
    expect(UserProfile.fromJson({'id': 7, 'displayName': 'X'}), isNull);
  });

  test('initials use the first two words', () {
    expect(user.initials, 'DC');
    expect(const UserProfile(id: '1', displayName: 'asif').initials, 'A');
    expect(const UserProfile(id: '1', displayName: '  ').initials, '?');
    expect(UserProfile.demo.initials, 'AQ');
  });
}
