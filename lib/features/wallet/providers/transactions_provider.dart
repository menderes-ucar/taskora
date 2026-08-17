import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/enums/transaction_type.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class TransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  TransactionsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => TransactionModel.fromMap(Map<String, dynamic>.from(json)))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Transactions are an accounting ledger and cannot be client-created.
  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String title,
    required String description,
    required bool isIncome,
  }) async {
    throw StateError(
      'İşlem geçmişi doğrudan istemciden yazılamaz. Finansal işlemi oluşturan server-side RPC kaydı üretmelidir.',
    );
  }
}

final transactionsProvider =
StateNotifierProvider<TransactionsNotifier, AsyncValue<List<TransactionModel>>>((ref) {
  return TransactionsNotifier(ref);
});
