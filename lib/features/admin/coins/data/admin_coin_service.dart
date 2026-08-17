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

      final data = response as List<dynamic>;
      return data.map((user) {
        final map = Map<String, dynamic>.from(user as Map);
        return AuthUser.fromMap(map);
      }).toList();
    } catch (e, stack) {
      debugPrint('🚨 [AdminCoinService Hata]: $e\n$stack');
      throw Exception('Kullanıcı bakiyeleri çekilirken hata oluştu: $e');
    }
  }

  /// The client sends only the target and signed delta. The database derives
  /// the authoritative before/after balance, enforces admin RBAC, locks the
  /// target ledger row and records an immutable coin transaction.
  Future<void> adjustUserBalance({
    required String userId,
    required double currentBalance,
    required double amountToAdd,
    required String adminNote,
  }) async {
    final normalizedUserId = userId.trim();
    final note = adminNote.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId boş olamaz.');
    }
    if (amountToAdd == 0 || !amountToAdd.isFinite) {
      throw ArgumentError('Coin değişimi sıfır olamaz.');
    }
    if (note.length < 3 || note.length > 500) {
      throw ArgumentError('Admin notu 3-500 karakter arasında olmalıdır.');
    }

    try {
      await _supabase.rpc(
        'admin_adjust_coins_secure',
        params: {
          'p_user_id': normalizedUserId,
          'p_delta': amountToAdd,
          'p_note': note,
        },
      );
    } on PostgrestException catch (e) {
      debugPrint('🚨 [AdminCoinService Hata]: ${e.message}');
      throw Exception(_mapCoinError(e));
    } catch (e) {
      throw Exception('Coin bakiyesi güncellenemedi: $e');
    }
  }

  String _mapCoinError(PostgrestException error) {
    switch (error.message) {
      case 'not_authorized':
        return 'Bu işlem için yetkiniz yok.';
      case 'target_not_found':
        return 'Kullanıcı bulunamadı.';
      case 'invalid_delta':
        return 'Geçersiz coin miktarı.';
      case 'insufficient_coins':
        return 'Kullanıcının coin bakiyesi yetersiz.';
      default:
        return error.message;
    }
  }
}
