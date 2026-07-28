import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/supabase_wallet_repositoy.dart';
import '../data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return SupabaseWalletRepository();
});