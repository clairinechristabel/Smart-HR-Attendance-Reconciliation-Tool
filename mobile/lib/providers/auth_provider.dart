// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Restore session from SharedPreferences ─────────────────
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_session');
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        _user = UserModel.fromJson(userData);
        _status = AuthStatus.authenticated;
        notifyListeners();
      } catch (_) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // ── Sign In ────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(email, password);
      if (user == null) {
        _status = AuthStatus.error;
        _errorMessage = 'User not found. Check your credentials.';
        notifyListeners();
        return false;
      }

      _user = user;
      _status = AuthStatus.authenticated;

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', json.encode(user.toJson()));

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Update local user model ────────────────────────────────
  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();

    // Persist updated session
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user_session', json.encode(updatedUser.toJson()));
    });
  }

  // ── Clear error ────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
