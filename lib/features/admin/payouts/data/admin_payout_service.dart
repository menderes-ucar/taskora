import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPayoutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPayoutRequests() async {
    try {
      final response = await _supabase
          .from('payout_requests')
          .select('*, profiles(name, email)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Çekim talepleri alınamadı: ${e.message}');
    } catch (e) {
      throw Exception('Çekim talepleri alınamadı: $e');
    }
  }

  /// All payout mutations go through the database RPC.
  /// The client intentionally does not send userId or amount: the RPC reads
  /// the authoritative payout row, checks the admin role, locks the row and
  /// performs the state transition atomically.
  Future<void> updatePayoutStatus({
    required String requestId,
    required String newStatus,
  }) async {
    final normalizedRequestId = requestId.trim();

    if (normalizedRequestId.isEmpty) {
      throw ArgumentError('requestId boş olamaz.');
    }

    if (newStatus != 'approved' && newStatus != 'rejected') {
      throw ArgumentError('Geçersiz payout durumu.');
    }

    try {
      await _supabase.rpc(
        'admin_update_payout_status',
        params: {
          'p_request_id': normalizedRequestId,
          'p_new_status': newStatus,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(_mapPayoutError(e));
    } catch (e) {
      throw Exception('Payout işlemi gerçekleştirilemedi: $e');
    }
  }

  String _mapPayoutError(PostgrestException error) {
    switch (error.message) {
      case 'not_authorized':
        return 'Bu işlem için yetkiniz yok.';
      case 'payout_not_found':
        return 'Para çekme talebi bulunamadı.';
      case 'payout_not_pending':
        return 'Bu para çekme talebi zaten işlenmiş.';
      case 'invalid_status':
        return 'Geçersiz işlem durumu.';
      case 'wallet_not_found':
        return 'Kullanıcının cüzdanı bulunamadı.';
      default:
        return error.message;
    }
  }
}
