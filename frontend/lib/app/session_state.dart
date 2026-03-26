import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_models.dart';

class SessionState extends ChangeNotifier {
  static const String _sessionKey = 'demo_session_user';

  DemoUser? _currentUser;
  bool _isInitialized = false;

  DemoUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      final data = jsonDecode(sessionJson) as Map<String, dynamic>;
      _currentUser = DemoUser.fromJson(data);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setSession(DemoUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> clearSession() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }
}
