import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'contract_repository.dart';
import 'mock_contract_repository.dart';
import 'supabase_contract_repository.dart';

final contractSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final useMockContractsProvider = Provider<bool>((ref) => false);

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  final useMock = ref.watch(useMockContractsProvider);

  if (useMock) {
    return MockContractRepository();
  }

  final supabase = ref.watch(contractSupabaseClientProvider);
  return SupabaseContractRepository(supabase);
});