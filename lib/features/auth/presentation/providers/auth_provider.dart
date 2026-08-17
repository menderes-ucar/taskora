import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../notification/data/services/notification_helper.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(sb.Supabase.instance.client);
});

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final AuthUser? user;
  final String? errorMessage;

  bool get isAdmin => user?.role.isAdminRole ?? false;

  bool get isSuperAdmin => user?.role == UserRole.superAdmin;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    AuthUser? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<sb.AuthState>? _authSubscription;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    restoreSession();
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      switch (data.event) {
        case sb.AuthChangeEvent.signedOut:
        case sb.AuthChangeEvent.userDeleted:
          state = AuthState.initial();
          break;
        case sb.AuthChangeEvent.userUpdated:
        case sb.AuthChangeEvent.tokenRefreshed:
        case sb.AuthChangeEvent.mfaChallengeVerified:
          unawaited(restoreSession());
          break;
        case sb.AuthChangeEvent.initialSession:
        case sb.AuthChangeEvent.signedIn:
        case sb.AuthChangeEvent.passwordRecovery:
          break;
      }
    });
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.restoreSession();
      if (user == null) {
        state = AuthState.initial();
        return;
      }
      state = state.copyWith(isLoading: false, isLoggedIn: true, user: user);

      await NotificationHelper.saveFcmToken();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false, isLoggedIn: true, user: user);

      await NotificationHelper.saveFcmToken();

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? companyName,
    String? industry,
    String? title,
    double? hourlyRate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        role: role,
        companyName: companyName,
        industry: industry,
        title: title,
        hourlyRate: hourlyRate,
      );
      state = state.copyWith(isLoading: false, isLoggedIn: true, user: user);

      await NotificationHelper.saveFcmToken();

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateRole(UserRole role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.updateRole(role);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repository.resetPassword(email);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _repository.resendVerificationEmail();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteAccount();
      state = AuthState.initial();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await NotificationHelper.clearCurrentDeviceToken();
    await _repository.signOut();
    state = AuthState.initial();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});