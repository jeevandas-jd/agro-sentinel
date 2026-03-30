import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'auth_models.dart';

class AuthService {
  AuthService({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<AppUser> login(LoginRequest request) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: request.email.trim(),
        password: request.password,
      );
      final user = result.user;
      if (user == null) {
        throw const AuthException('Unable to sign in. Please try again.');
      }
      return _loadOrCreateProfile(user);
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    }
  }

  Future<AppUser> register(RegisterRequest request) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: request.email.trim(),
        password: request.password,
      );
      final user = result.user;
      if (user == null) {
        throw const AuthException('Unable to create account. Please try again.');
      }

      final profile = AppUser(
        name: request.name.trim(),
        email: user.email ?? request.email.trim().toLowerCase(),
        region: request.region.trim(),
      );
      await _saveProfile(user.uid, profile);
      await user.updateDisplayName(profile.name);
      return profile;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    }
  }

  Future<AppUser> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed in user found.');
    }
    return _loadOrCreateProfile(user);
  }

  Future<AppUser> updateProfile({
    required String name,
    required String region,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed in user found.');
    }
    final updated = AppUser(
      name: name.trim(),
      email: user.email ?? '',
      region: region.trim(),
    );
    await _saveProfile(user.uid, updated);
    await user.updateDisplayName(updated.name);
    return updated;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('No signed in user found.');
    }
    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed in user found.');
    }
    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    } on FirebaseException catch (_) {
      throw const AuthException('Failed to delete account data.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser> _loadOrCreateProfile(firebase_auth.User authUser) async {
    try {
      final doc = await _firestore.collection('users').doc(authUser.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? <String, dynamic>{};
        return AppUser.fromJson(data);
      }
      final fallback = AppUser(
        name: authUser.displayName?.trim().isNotEmpty == true
            ? authUser.displayName!.trim()
            : 'Farmer',
        email: authUser.email ?? '',
        region: 'Unknown Region',
      );
      await _saveProfile(authUser.uid, fallback);
      return fallback;
    } on FirebaseException catch (_) {
      throw const AuthException('Failed to load account details.');
    }
  }

  Future<void> _saveProfile(String uid, AppUser user) async {
    await _firestore.collection('users').doc(uid).set(user.toJson());
  }

  String _mapFirebaseError(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'requires-recent-login':
        return 'Please log in again to complete this action.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
