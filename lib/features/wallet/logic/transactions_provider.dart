import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/enums/transaction_type.dart';
import '../../../../shared/models/transaction_model.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../data/transaction_repository_provider.dart';


class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final user = ref.read(authProvider).user;

    if (user == null || user.id.trim().isEmpty) {
      return [];
    }

    return _load(user.id);
  }

  Future<List<TransactionModel>> _load(String userId) async {
    final repo = ref.read(transactionRepositoryProvider);
    return repo.getTransactionsByUser(userId);
  }

  Future<void> refreshTransactions() async {
    final user = ref.read(authProvider).user;
    if (user == null || user.id.trim().isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => _load(user.id));
  }

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String title,
    required String description,
    required bool isIncome,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null || user.id.trim().isEmpty) return;

    final repo = ref.read(transactionRepositoryProvider);

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: user.id,
      amount: amount,
      type: type,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      isIncome: isIncome,
    );

    state = await AsyncValue.guard(() async {
      await repo.addTransaction(transaction);
      return _load(user.id);
    });
  }
}

final transactionsProvider =
AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
  TransactionsNotifier.new,
);