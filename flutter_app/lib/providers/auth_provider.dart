import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  User?   _user;
  bool    _loading = false;
  String? _error;

  bool    get isLoggedIn => _user != null;
  bool    get loading    => _loading;
  String? get error      => _error;
  User?   get user       => _user;

  AuthProvider() {
    _service.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      await _service.signIn(email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }
}
