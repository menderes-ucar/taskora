import '../../../../shared/models/transaction_model.dart';
import 'transaction_repository.dart';

class MockTransactionRepository implements TransactionRepository {
  final List<TransactionModel> _transactions = [];

  @override
  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    final items = _transactions
        .where((transaction) => transaction.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return items;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.insert(0, transaction);
  }
}