import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../shared/models/wallet_model.dart';
import 'wallet_repository.dart';

class SupabaseWalletRepository implements WalletRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _table = 'wallets';

  @override
  Future<WalletModel> getWallet(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      throw StateError('Kullanıcı cüzdanı bulunamadı.');
    }

    return WalletModel(
      userId: response['user_id'] as String,
      balance: (response['balance'] as num).toDouble(),
    );
  }

  @override
  Future<void> deposit(String userId, double amount) async {
    throw StateError('Cüzdan bakiyesi doğrudan değiştirilemez.');
  }

  @override
  Future<void> withdraw(String userId, double amount) async {
    throw StateError('Para çekme payout request üzerinden yapılmalıdır.');
  }
}
