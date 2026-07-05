import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mock_proposal_repository.dart';
import 'proposal_repository.dart';
import 'supabase_proposal_repository.dart';

final proposalSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final useMockProposalsProvider = Provider<bool>((ref) => false);

final proposalRepositoryProvider = Provider<ProposalRepository>((ref) {
  final useMock = ref.watch(useMockProposalsProvider);

  if (useMock) {
    return MockProposalRepository();
  }

  final supabase = ref.watch(proposalSupabaseClientProvider);
  return SupabaseProposalRepository(supabase);
});