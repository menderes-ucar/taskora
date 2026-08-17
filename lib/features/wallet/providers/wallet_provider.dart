import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/wallet_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class WalletNotifier extends StateNotifier<AsyncValue<WalletModel>> {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  WalletNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      state = AsyncValue.error(
        'Kullanıcı oturumu bulunamadı',
        StackTrace.current,
      );
      return;
    }

    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        // Wallet provisioning is server-side. A missing wallet is an integrity error,
        // not permission to create financial accounts from the client.
        throw StateError('Kullanıcı cüzdanı bulunamadı.');
      }

      state = AsyncValue.data(WalletModel.fromMap(response));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Direct balance mutation is intentionally forbidden.
  /// Top-ups must come from a verified payment flow and server-side settlement.
  Future<void> deposit(double amount) async {
    throw StateError(
      'Cüzdan bakiyesi doğrudan değiştirilemez. Ödeme akışını kullanın.',
    );
  }

  Future<String> createPayoutRequest({
    required double amount,
    required String bankName,
    required String bankAccount,
  }) async {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');

    final result = await _supabase.rpc('create_payout_request_atomic', params: {
      'p_amount': amount,
      'p_bank_name': bankName.trim(),
      'p_bank_account': bankAccount.trim(),
    });

    await fetchWallet();
    return result.toString();
  }

  Future<bool> upgradeToPremium() async {
    throw StateError(
      'Abonelik yükseltme doğrudan cüzdan bakiyesi ile yapılamaz. Billing akışını kullanın.',
    );
  }
}

final walletProvider =
StateNotifierProvider<WalletNotifier, AsyncValue<WalletModel>>((ref) {
  return WalletNotifier(ref);
});
