import '../../../../shared/models/wallet_model.dart';

abstract class WalletRepository {
  Future<WalletModel> getWallet(String userId);

  Future<void> deposit(String userId, double amount);

  Future<void> withdraw(String userId, double amount);
}