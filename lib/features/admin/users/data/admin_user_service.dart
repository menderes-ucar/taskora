import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/user_model.dart';

class AdminUserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Tüm kullanıcıları getir
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

  // Kullanıcı ban durumunu değiştir (banla / engeli kaldır)
  Future<void> toggleUserBan(String userId, bool isBanned) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_banned': isBanned})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Kullanıcı ban durumu güncellenemedi: $e');
    }
  }
}