import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import 'repositories/proposal_repository.dart';
import 'repositories/supabase_proposal_repository.dart';

final proposalSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final proposalRepositoryProvider = Provider<ProposalRepository>((ref) {
  final supabase = ref.watch(proposalSupabaseClientProvider);
  return SupabaseProposalRepository(supabase);
});