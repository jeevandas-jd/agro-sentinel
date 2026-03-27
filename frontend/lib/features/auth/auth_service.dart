import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_models.dart';

class AuthService {
  static const String _usersStorageKey = 'demo_registered_users';

  Future<DemoUser> login(LoginRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final users = await _loadUsers();

    final normalizedEmail = request.email.trim().toLowerCase();
    if (!users.containsKey(normalizedEmail)) {
      throw const AuthException('No account found for that email.');
    }

    final account = users[normalizedEmail]!;
    if (account.password != request.password) {
      throw const AuthException('Incorrect password.');
    }

    return DemoUser(
      name: account.name,
      email: normalizedEmail,
      region: account.region,
    );
  }

  Future<DemoUser> register(RegisterRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final users = await _loadUsers();

    final normalizedEmail = request.email.trim().toLowerCase();
    if (users.containsKey(normalizedEmail)) {
      throw const AuthException('An account already exists for this email.');
    }

    users[normalizedEmail] = _StoredUser(
      name: request.name.trim(),
      email: normalizedEmail,
      password: request.password,
      region: request.region.trim(),
    );
    await _saveUsers(users);

    return DemoUser(
      name: request.name.trim(),
      email: normalizedEmail,
      region: request.region.trim(),
    );
  }

  Future<DemoUser> updateProfile({
    required String email,
    required String name,
    required String region,
  }) async {
    final users = await _loadUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final existing = users[normalizedEmail];
    if (existing == null) {
      throw const AuthException('Account not found for profile update.');
    }

    users[normalizedEmail] = _StoredUser(
      name: name.trim(),
      email: normalizedEmail,
      password: existing.password,
      region: region.trim(),
    );
    await _saveUsers(users);

    return DemoUser(
      name: name.trim(),
      email: normalizedEmail,
      region: region.trim(),
    );
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final users = await _loadUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final existing = users[normalizedEmail];
    if (existing == null) {
      throw const AuthException('Account not found.');
    }
    if (existing.password != currentPassword) {
      throw const AuthException('Current password is incorrect.');
    }
    users[normalizedEmail] = _StoredUser(
      name: existing.name,
      email: existing.email,
      password: newPassword,
      region: existing.region,
    );
    await _saveUsers(users);
  }

  Future<void> deleteAccount(String email) async {
    final users = await _loadUsers();
    final normalizedEmail = email.trim().toLowerCase();
    if (!users.containsKey(normalizedEmail)) {
      throw const AuthException('Account not found.');
    }
    users.remove(normalizedEmail);
    await _saveUsers(users);
  }

  Future<Map<String, _StoredUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getStringList(_usersStorageKey) ?? <String>[];

    final users = <String, _StoredUser>{};
    for (final row in serialized) {
      final parsed = _StoredUser.tryParse(row);
      if (parsed != null) {
        users[parsed.email] = parsed;
      }
    }

    users.putIfAbsent(
      'demo@agrisentinel.app',
      () => const _StoredUser(
        name: 'Rajan Pillai',
        email: 'demo@agrisentinel.app',
        password: 'demo123',
        region: 'Palakkad District, Kerala',
      ),
    );
    return users;
  }

  Future<void> _saveUsers(Map<String, _StoredUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = users.values.map((user) => user.serialize()).toList();
    await prefs.setStringList(_usersStorageKey, serialized);
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class _StoredUser {
  final String name;
  final String email;
  final String password;
  final String region;

  const _StoredUser({
    required this.name,
    required this.email,
    required this.password,
    required this.region,
  });

  String serialize() => '$name|$email|$password|$region';

  static _StoredUser? tryParse(String value) {
    final parts = value.split('|');
    if (parts.length != 4) {
      return null;
    }
    return _StoredUser(
      name: parts[0],
      email: parts[1],
      password: parts[2],
      region: parts[3],
    );
  }
}
