import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/models/wallet_model.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/wallet_repository_provider.dart';

class WalletNotifier extends AsyncNotifier<WalletModel> {
  @override
  Future<WalletModel> build() async {
    final user = ref.read(authProvider).user;

    if (user == null || user.id.trim().isEmpty) {
      return const WalletModel(userId: '', balance: 0);
    }

    return _load(user.id);
  }

  Future<WalletModel> _load(String userId) async {
    if (userId.trim().isEmpty) {
      return const WalletModel(userId: '', balance: 0);
    }

    final repo = ref.read(walletRepositoryProvider);
    return repo.getWallet(userId);
  }

  Future<void> refreshWallet() async {
    final user = ref.read(authProvider).user;
    if (user == null || user.id.trim().isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => _load(user.id));
  }

  Future<void> deposit(double amount) async {
    final user = ref.read(authProvider).user;
    if (user == null || user.id.trim().isEmpty) return;

    final repo = ref.read(walletRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repo.deposit(user.id, amount);
      return _load(user.id);
    });
  }

  Future<void> withdraw(double amount) async {
    final user = ref.read(authProvider).user;
    if (user == null || user.id.trim().isEmpty) return;

    final repo = ref.read(walletRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repo.withdraw(user.id, amount);
      return _load(user.id);
    });
  }
}

final walletProvider =
AsyncNotifierProvider<WalletNotifier, WalletModel>(
  WalletNotifier.new,
);