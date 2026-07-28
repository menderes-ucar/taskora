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
    } catch (e) {
      throw Exception('Çekim talepleri alınamadı: $e');
    }
  }

  Future<void> updatePayoutStatus({
    required String requestId,
    required String userId,
    required double amount,
    required String newStatus,
  }) async {
    try {
      await _supabase
          .from('payout_requests')
          .update({'status': newStatus})
          .eq('id', requestId);

      if (newStatus == 'rejected') {
        final walletRes = await _supabase
            .from('wallets')
            .select('balance')
            .eq('user_id', userId)
            .single();

        final currentBalance = (walletRes['balance'] as num?)?.toDouble() ?? 0.0;

        await _supabase
            .from('wallets')
            .update({'balance': currentBalance + amount})
            .eq('user_id', userId);
      }
    } catch (e) {
      throw Exception('İşlem güncellenirken hata oluştu: $e');
    }
  }
}