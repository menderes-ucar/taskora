import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:taskora/features/auth/domain/entities/auth_user.dart';

class AdminCoinService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AuthUser>> getUsersWithBalances() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((user) {
        final map = Map<String, dynamic>.from(user as Map);
        // 🚀 AuthUser.fromMap burada sorunsuz çalışacaktır:
        return AuthUser.fromMap(map);
      }).toList();
    } catch (e, stack) {
      debugPrint('🚨 [AdminCoinService Hata]: $e\n$stack');
      throw Exception('Kullanıcı bakiyeleri çekilirken hata oluştu: $e');
    }
  }

  Future<void> adjustUserBalance({
    required String userId,
    required double currentBalance,
    required double amountToAdd,
    required String adminNote,
  }) async {
    try {
      await _supabase.rpc('adjust_user_balance_atomic', params: {
        'p_user_id': userId,
        'p_amount': amountToAdd,
        'p_transaction_type': amountToAdd > 0 ? 'admin_credit' : 'admin_deduction',
        'p_description': 'Admin İşlemi: $adminNote',
      });
    } catch (e) {
      debugPrint('🚨 [adjustUserBalance Hata]: $e');
      throw Exception('Bakiye güncellenemedi: $e');
    }
  }
}