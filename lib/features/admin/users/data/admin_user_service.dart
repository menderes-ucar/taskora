import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/user_model.dart';

class AdminUserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserModel.fromMap(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcılar çekilirken hata oluştu: $e');
    }
  }

  /// Ban/unban is a privileged state transition. The client never updates
  /// profiles.is_banned directly; the database verifies the current actor's
  /// admin role, protects privileged accounts, and writes an audit event.
  Future<void> toggleUserBan(String userId, bool isBanned) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId boş olamaz.');
    }

    try {
      await _supabase.rpc(
        'admin_set_user_ban_secure',
        params: {
          'p_user_id': normalizedUserId,
          'p_is_banned': isBanned,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(_mapAdminUserError(e));
    } catch (e) {
      throw Exception('Kullanıcı ban durumu güncellenemedi: $e');
    }
  }

  String _mapAdminUserError(PostgrestException error) {
    switch (error.message) {
      case 'not_authorized':
        return 'Bu işlem için yetkiniz yok.';
      case 'target_not_found':
        return 'Kullanıcı bulunamadı.';
      case 'protected_account':
        return 'Bu hesap bu işlem için korumalıdır.';
      case 'cannot_modify_self':
        return 'Kendi hesabınızın ban durumunu değiştiremezsiniz.';
      default:
        return error.message;
    }
  }
}
