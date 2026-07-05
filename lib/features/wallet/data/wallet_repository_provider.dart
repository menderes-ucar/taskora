import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../mock_wallet_repositoy.dart';
import '../wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return MockWalletRepository();
});