import '../../../../shared/enums/user_role.dart';
import '../../domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser?> restoreSession();
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? companyName,
    String? industry,
    String? title,
    double? hourlyRate,
  });
  Future<void> signOut();
  Future<AuthUser> updateRole(UserRole role);
  Future<void> resetPassword(String email);
  Future<void> resendVerificationEmail();
  Future<void> deleteAccount();
}