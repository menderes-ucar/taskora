import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_transaction_repository.dart';
import 'transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return MockTransactionRepository();
});