import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../shared/enums/user_role.dart';
import '../../domain/entities/auth_user.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final sb.SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<AuthUser?> restoreSession() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .single();

      return AuthUser.fromMap(
        profile,
        emailVerified: currentUser.emailConfirmedAt != null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = await restoreSession();
    if (user == null) {
      throw Exception('Giriş başarılı ancak profil bilgisi alınamadı.');
    }
    return user;
  }

  @override
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
  }) async {
    final fullName = '$firstName $lastName'.trim();

    final authResponse = await _client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {
        'name': fullName,
        'role': role.name,
      },
    );

    final sessionUser = authResponse.user;

    if (sessionUser != null) {
      await _client.from('profiles').upsert({
        'id': sessionUser.id,
        'name': fullName,
        'email': email.trim(),
        'role': role.name,
        'company_name': companyName,
        'industry': industry,
        'title': title,
        'hourly_rate': hourlyRate,
        'coins': 50,
        'subscription_tier': 'free',
        'is_subscribed': false,
        'active_job_limit': 3,
        'proposal_limit': 10,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    final user = await restoreSession();
    if (user == null) {
      throw Exception('Kayıt oluşturuldu, lütfen giriş yapın.');
    }
    return user;
  }

  @override
  Future<AuthUser> updateRole(UserRole role) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('Oturum bulunamadı.');

    await _client.from('profiles').update({
      'role': role.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', currentUser.id);

    final user = await restoreSession();
    if (user == null) throw Exception('Rol güncellenemedi.');
    return user;
  }

  @override
  Future<void> signOut() async => await _client.auth.signOut();

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> resendVerificationEmail() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser?.email == null) throw Exception('Aktif kullanıcı e-postası bulunamadı.');
    await _client.auth.resend(
      type: sb.OtpType.signup,
      email: currentUser!.email!,
    );
  }

  @override
  Future<void> deleteAccount() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return;

    await _client.from('profiles').delete().eq('id', currentUser.id);
    await _client.rpc('delete_user_account');
    await signOut();
  }
}