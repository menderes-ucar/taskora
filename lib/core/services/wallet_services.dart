import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_exception.dart';
import '../../shared/models/wallet_model.dart';
import '../../shared/models/transaction_model.dart';

abstract class IWalletService {
  Future<WalletModel> getWallet(String userId);
  Future<List<TransactionModel>> getTransactions(
      String userId, {
        int page = 1,
        String? type,
      });
  Future<void> addFunds(String userId, double amount, String paymentMethod);
  Future<void> withdrawFunds(String userId, double amount);
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<double> getBalance(String userId);
}

class SupabaseWalletService implements IWalletService {
  final SupabaseClient _supabase;

  SupabaseWalletService(this._supabase);

  @override
  Future<WalletModel> getWallet(String userId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        throw StateError('Kullanıcı cüzdanı bulunamadı.');
      }

      return WalletModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions(
      String userId, {
        int page = 1,
        String? type,
      }) async {
    try {
      const limit = 20;
      final offset = (page - 1) * limit;

      var query = _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId);

      if (type != null && type.isNotEmpty) {
        query = query.eq('type', type);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((txn) => TransactionModel.fromJson(Map<String, dynamic>.from(txn)))
          .toList();
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> addFunds(
      String userId,
      double amount,
      String paymentMethod,
      ) async {
    // Deprecated by design. A wallet credit must originate from a verified
    // payment settlement, never from a client-supplied amount.
    throw StateError(
      'Cüzdan bakiyesi doğrudan eklenemez. Doğrulanmış ödeme akışını kullanın.',
    );
  }

  @override
  Future<void> withdrawFunds(String userId, double amount) async {
    throw StateError(
      'Para çekme işlemi payout request akışı üzerinden yapılmalıdır.',
    );
  }

  @override
  Future<TransactionModel> createTransaction(
      TransactionModel transaction,
      ) async {
    throw StateError(
      'Muhasebe işlemleri istemciden doğrudan oluşturulamaz.',
    );
  }

  @override
  Future<double> getBalance(String userId) async {
    final wallet = await getWallet(userId);
    return wallet.balance;
  }
}
