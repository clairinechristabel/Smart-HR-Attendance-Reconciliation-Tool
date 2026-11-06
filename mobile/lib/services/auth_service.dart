// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'mock_data.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Sign In ───────────────────────────────────────────────
  Future<UserModel?> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    if (kUseMockDatabase) {
      if (MockDatabase.users.containsKey(cleanEmail)) {
        final user = MockDatabase.users[cleanEmail]!;
        final expectedPassword =
            user.isHRAdmin ? kAdminPassword : kStaffPassword;
        if (password != expectedPassword) {
          throw AuthException('Invalid password for demo user.');
        }
        return user;
      }
      throw AuthException('No user found with email "$cleanEmail". Try the demo accounts below.');
    }

    // 1. Try real Supabase if online
    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('email', cleanEmail)
          .maybeSingle()
          .timeout(kNetworkTimeout);

      if (response != null) {
        final user = UserModel.fromJson(response);
        final customPassword = response['password'] as String?;
        final expectedPassword = (customPassword != null && customPassword.isNotEmpty)
            ? customPassword
            : (user.isHRAdmin ? kAdminPassword : kStaffPassword);
        if (password != expectedPassword) {
          throw AuthException('Invalid password.');
        }
        return user;
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // Supabase is down/paused/offline: fall back to MockDatabase
    }

    // 2. Demo fallback
    if (MockDatabase.users.containsKey(cleanEmail)) {
      final user = MockDatabase.users[cleanEmail]!;
      final expectedPassword =
          user.isHRAdmin ? kAdminPassword : kStaffPassword;
      if (password != expectedPassword) {
        throw AuthException('Invalid password for demo user.');
      }
      return user;
    }

    throw AuthException('No user found with email "$cleanEmail". Try the demo accounts below.');
  }

  // ── Get current user profile ──────────────────────────────
  Future<UserModel?> getCurrentUserProfile(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (kUseMockDatabase) {
      return MockDatabase.users[cleanEmail];
    }

    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('email', cleanEmail)
          .maybeSingle()
          .timeout(kNetworkTimeout);

      if (response != null) return UserModel.fromJson(response);
    } catch (_) {}

    return MockDatabase.users[cleanEmail];
  }

  // ── Update profile ────────────────────────────────────────
  Future<void> updateProfile({
    required String userId,
    String? phone,
    String? fullName,
  }) async {
    final Map<String, dynamic> updates = {};
    if (phone != null) updates['phone'] = phone;
    if (fullName != null) updates['full_name'] = fullName;

    if (updates.isEmpty) return;

    if (kUseMockDatabase) {
      for (final u in MockDatabase.users.values) {
        if (u.id == userId) {
          MockDatabase.users[u.email] = u.copyWith(phone: phone, fullName: fullName);
          break;
        }
      }
      return;
    }

    try {
      await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .timeout(kNetworkTimeout);
    } catch (_) {
      for (final u in MockDatabase.users.values) {
        if (u.id == userId) {
          MockDatabase.users[u.email] = u.copyWith(phone: phone, fullName: fullName);
          break;
        }
      }
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
