import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/supabase_transaction_repository.dart';

// 🚀 ÇÖZÜM: Döndürülen nesne türü tam olarak SupabaseTransactionRepository olarak eşitlendi
final transactionRepositoryProvider = Provider<SupabaseTransactionRepository>((ref) {
  return SupabaseTransactionRepository();
});