import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../shared/enums/user_role.dart';
import '../../../../shared/models/user_model.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.isLoggedIn,
    required this.isLoading,
    required this.user,
    required this.errorMessage,
  });

  factory AuthState.initial() {
    return const AuthState(
      isLoggedIn: false,
      isLoading: false,
      user: null,
      errorMessage: null,
    );
  }

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _restoreSession();

    _authSubscription =
        _client.auth.onAuthStateChange.listen((supabase.AuthState data) {
          _restoreSession();
        });
  }

  final supabase.SupabaseClient _client = supabase.Supabase.instance.client;

  StreamSubscription<supabase.AuthState>? _authSubscription;


  Future<void> _restoreSession() async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      state = AuthState.initial();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .single();

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        user: _mapProfileToUser(profile),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Profil yüklenemedi: $e',
      );
    }
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'employer':
        return UserRole.employer;
      case 'admin':
        return UserRole.admin;
      case 'freelancer':
      default:
        return UserRole.freelancer;
    }
  }

  UserModel _mapProfileToUser(Map<String, dynamic> profile) {
    return UserModel(
      id: profile['id'] as String,
      name: (profile['name'] ?? '') as String,
      email: (profile['email'] ?? '') as String,
      role: _parseRole(profile['role'] as String?),
      title: profile['title'] as String?,
      bio: profile['bio'] as String?,
      rating: profile['rating'] == null
          ? 0
          : (profile['rating'] as num).toDouble(),
      reviewCount: (profile['review_count'] ?? 0) as int,
      completedJobs: (profile['completed_jobs'] ?? 0) as int,
      skills: const [],
    );
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _restoreSession();
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Giriş hatası: $e',
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();

      await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'name': fullName,
          'role': role.name,
        },
      );

      state = state.copyWith(
        isLoading: false,
        clearError: true,
      );
      return true;
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Kayıt hatası: $e',
      );
      return false;
    }
  }

  Future<bool> updateRole(UserRole role) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      state = state.copyWith(
        errorMessage: 'Oturum bulunamadı',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _client.from('profiles').update({
        'role': role.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      await _restoreSession();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Rol güncellenemedi: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    state = AuthState.initial();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});