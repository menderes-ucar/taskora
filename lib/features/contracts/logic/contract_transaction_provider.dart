import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/services/contract_transaction_service.dart';

final contractTransactionProvider =
Provider<ContractTransactionService>((ref) {
  final supabase = Supabase.instance.client;

  return ContractTransactionService(
    supabase,
    maxRetries: 3,
    timeout: const Duration(seconds: 30),
    initialRetryDelay: const Duration(milliseconds: 500),
  );
});
