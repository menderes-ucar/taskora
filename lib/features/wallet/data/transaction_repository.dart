import '../../../../shared/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactionsByUser(String userId);

  Future<void> addTransaction(TransactionModel transaction);
}