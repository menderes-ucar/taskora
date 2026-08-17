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

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', currentUser.id)
        .maybeSingle();

    if (profile == null) {
      throw StateError(
        'Authenticated user has no profile. Check profile provisioning and RLS.',
      );
    }

    return AuthUser.fromMap(
      profile,
      emailVerified: currentUser.emailConfirmedAt != null,
    );
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = await restoreSession();
    if (user == null) {
      throw StateError('Giriş başarılı ancak profil bilgisi alınamadı.');
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
    if (!role.isSelfAssignable) {
      throw StateError('Bu rol kayıt ekranından atanamaz.');
    }

    final fullName = '$firstName $lastName'.trim();

    final authResponse = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'name': fullName,
        'role': role.name,
        'company_name': companyName,
        'industry': industry,
        'title': title,
        'hourly_rate': hourlyRate,
      },
    );

    // Profile provisioning is performed by the database trigger.
    // The client must not be responsible for coins, subscription or entitlements.
    final sessionUser = authResponse.user;
    if (sessionUser == null) {
      throw StateError('Kayıt oluşturulamadı.');
    }

    final user = await restoreSession();
    if (user == null) {
      throw StateError('Kayıt oluşturuldu, profil hazırlanamadı.');
    }
    return user;
  }

  @override
  Future<AuthUser> updateRole(UserRole role) async {
    if (!role.isSelfAssignable) {
      throw StateError('Bu rol bu akıştan atanamaz.');
    }

    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw StateError('Oturum bulunamadı.');

    await _client.rpc('update_own_role', params: {
      'p_role': role.name,
    });

    final user = await restoreSession();
    if (user == null) throw StateError('Rol güncellenemedi.');
    return user;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> resendVerificationEmail() async {
    final currentUser = _client.auth.currentUser;
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      throw StateError('Aktif kullanıcı e-postası bulunamadı.');
    }

    await _client.auth.resend(
      type: sb.OtpType.signup,
      email: email,
    );
  }

  @override
  Future<void> deleteAccount() async {
    if (_client.auth.currentUser == null) return;

    // The RPC owns the deletion boundary so dependent rows and auth.users
    // are handled atomically/server-side. The client never deletes profiles directly.
    await _client.rpc('delete_user_account');
    await signOut();
  }
}
