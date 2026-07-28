import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../shared/models/wallet_model.dart';
import 'wallet_repository.dart';

class SupabaseWalletRepository implements WalletRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _table = 'wallets';

  @override
  Future<WalletModel> getWallet(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // 🚀 'created_at' kaldırıldı, varsayılan tablo yapısıyla ekleniyor
        final newWalletMap = {
          'user_id': userId,
          'balance': 0.0,
        };

        await _client.from(_table).insert(newWalletMap);
        return WalletModel(userId: userId, balance: 0.0);
      }

      return WalletModel(
        userId: response['user_id'] as String,
        balance: (response['balance'] as num).toDouble(),
      );
    } catch (e) {
      return WalletModel(userId: userId, balance: 0.0);
    }
  }

  @override
  Future<void> deposit(String userId, double amount) async {
    if (amount <= 0) return;

    await _client.rpc('increment_wallet_balance', params: {
      'p_user_id': userId,
      'p_amount': amount,
    });
  }

  @override
  Future<void> withdraw(String userId, double amount) async {
    if (amount <= 0) return;

    await _client.rpc('decrement_wallet_balance', params: {
      'p_user_id': userId,
      'p_amount': amount,
    });
  }
}