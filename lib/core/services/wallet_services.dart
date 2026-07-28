// lib/core/services/wallet_service.dart

import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../error/app_exception.dart';
import '../../shared/models/wallet_model.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/enums/transaction_type.dart';

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
      // Get or create wallet
      var response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create new wallet
        response = await _supabase
            .from('wallets')
            .insert({
          'user_id': userId,
          'balance': 0.0,
          'created_at': DateTime.now().toIso8601String(),
        })
            .select()
            .single();
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
      int offset = (page - 1) * limit;

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

      return List<TransactionModel>.from(
        (response as List).map((txn) => TransactionModel.fromJson(txn)),
      );
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
    try {
      // Get current wallet
      final wallet = await getWallet(userId);

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({
        'balance': wallet.balance + amount,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', userId);

      // Create transaction record
      await createTransaction(
        TransactionModel(
          id: '',
          userId: userId,
          amount: amount,
          type: TransactionType.deposit,
          title: 'Add Funds',
          description: 'Funds added via $paymentMethod',
          createdAt: DateTime.now(),
          isIncome: true,
        ),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> withdrawFunds(String userId, double amount) async {
    try {
      // Get current wallet
      final wallet = await getWallet(userId);

      // Check sufficient balance
      if (wallet.balance < amount) {
        throw AppException(
          message: 'Insufficient balance',
          type: AppExceptionType.validation,
        );
      }

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({
        'balance': wallet.balance - amount,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', userId);

      // Create transaction record
      await createTransaction(
        TransactionModel(
          id: '',
          userId: userId,
          amount: amount,
          type: TransactionType.withdrawal,
          title: 'Withdrawal',
          description: 'Withdrawal request',
          createdAt: DateTime.now(),
          isIncome: false,
        ),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<TransactionModel> createTransaction(
      TransactionModel transaction,
      ) async {
    try {
      final response = await _supabase
          .from('transactions')
          .insert({
        'user_id': transaction.userId,
        'amount': transaction.amount,
        'type': transaction.type,
        'status': transaction.status,
        'description': transaction.description,
        'created_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<double> getBalance(String userId) async {
    try {
      final wallet = await getWallet(userId);
      return wallet.balance;
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }
}
