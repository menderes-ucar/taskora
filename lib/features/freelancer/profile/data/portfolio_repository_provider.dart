import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'portfolio_repository.dart';
import 'supabase_portfolio_repository.dart';

final portfolioSupabaseClientProvider =
rp.Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final portfolioRepositoryProvider =
rp.Provider<PortfolioRepository>((ref) {
  return SupabasePortfolioRepository(
    ref.watch(portfolioSupabaseClientProvider),
  );
});