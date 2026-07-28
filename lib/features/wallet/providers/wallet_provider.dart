import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/wallet_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class WalletNotifier extends StateNotifier<AsyncValue<WalletModel>> {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  WalletNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      state = AsyncValue.error('Kullanıcı oturumu bulunamadı', StackTrace.current);
      return;
    }

    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        // 🚀 'created_at' kaldırıldı, varsayılan sütun yapısıyla oluşturuluyor
        final newWallet = await _supabase
            .from('wallets')
            .insert({
          'user_id': currentUser.id,
          'balance': 0.0,
        })
            .select()
            .single();
        state = AsyncValue.data(WalletModel.fromMap(newWallet));
      } else {
        state = AsyncValue.data(WalletModel.fromMap(response));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deposit(double amount) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      final currentBalance = state.value?.balance ?? 0.0;
      final newBalance = currentBalance + amount;

      // 🚀 'updated_at' güncellenmesi kaldırıldı
      await _supabase
          .from('wallets')
          .update({
        'balance': newBalance,
      })
          .eq('user_id', currentUser.id);

      await fetchWallet();
    } catch (e) {
      throw Exception('Bakiye yükleme başarısız: $e');
    }
  }

  Future<bool> upgradeToPremium() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return false;

    try {
      final currentBalance = state.value?.balance ?? 0.0;

      if (currentBalance < 150.0) {
        throw Exception('Yetersiz Bakiye! Premium üyelik için en az ₺150 bakiye gereklidir.');
      }

      await _supabase
          .from('wallets')
          .update({
        'balance': currentBalance - 150.0,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', currentUser.id);

      await _supabase
          .from('profiles')
          .update({
        'subscription_tier': 'premium',
        'active_job_limit': 30,
        'proposal_limit': 100,
      })
          .eq('id', currentUser.id);

      await fetchWallet();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}

final walletProvider =
StateNotifierProvider<WalletNotifier, AsyncValue<WalletModel>>((ref) {
  return WalletNotifier(ref);
});