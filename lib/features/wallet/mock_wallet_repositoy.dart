import '../../../../shared/models/wallet_model.dart';
import 'wallet_repository.dart';

class MockWalletRepository implements WalletRepository {
  final Map<String, WalletModel> _wallets = {};

  @override
  Future<WalletModel> getWallet(String userId) async {
    return _wallets[userId] ?? WalletModel(userId: userId, balance: 0);
  }

  @override
  Future<void> deposit(String userId, double amount) async {
    final wallet = await getWallet(userId);

    _wallets[userId] = wallet.copyWith(
      balance: wallet.balance + amount,
    );
  }

  @override
  Future<void> withdraw(String userId, double amount) async {
    final wallet = await getWallet(userId);

    _wallets[userId] = wallet.copyWith(
      balance: wallet.balance - amount,
    );
  }
}