import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../coin/presentation/pages/coin_store_page.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/wallet_provider.dart';
import 'add_funds_page.dart';
import 'withdraw_page.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(walletProvider);
    ref.invalidate(transactionsProvider);
  }

  Future<void> _quickDeposit(double amount) async {
    final authUser = ref.read(authProvider).user;
    if (authUser == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFundsPage(userId: authUser.id, initialAmount: amount),
      ),
    );

    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final currentUserId = authUser?.id;

    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text(
            'Kullanıcı oturumu bulunamadı.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Cüzdanım',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppColors.primaryDark,
        child: walletAsync.when(
          data: (wallet) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 🚀 Bakiye Kartı
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E2238), Color(0xFF103847), Color(0xFF0BA99C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kullanılabilir Bakiye',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₺${wallet.balance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB800),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CoinStorePage()),
                              ),
                              icon: const Icon(Icons.monetization_on_rounded, size: 16),
                              label: const Text('Coin Al', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddFundsPage(userId: currentUserId)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Para Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => WithdrawPage(userId: currentUserId)),
                              ),
                              icon: const Icon(Icons.north_east_rounded, size: 16),
                              label: const Text('Para Çek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Hızlı Bakiye Yükle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _QuickAmountCard(amount: 100, onTap: () => _quickDeposit(100))),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAmountCard(amount: 250, onTap: () => _quickDeposit(250))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _QuickAmountCard(amount: 500, onTap: () => _quickDeposit(500))),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAmountCard(amount: 1000, onTap: () => _quickDeposit(1000))),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('İşlem Geçmişi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 12),

                // 🚀 İşlem Geçmişi Liste Alanı
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: const Center(
                          child: Text('Henüz bir işlem bulunmuyor.', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }
                    return Column(children: transactions.map((tx) => _TransactionCard(transaction: tx)).toList());
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white))),
                  error: (error, _) => Center(child: Text('İşlemler yüklenemedi: $error', style: const TextStyle(color: Colors.white70))),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Cüzdan verisi alınamadı:\n$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _refreshAll,
                  child: const Text('Tekrar Deneyin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.isIncome ? AppColors.success : AppColors.danger;
    final prefix = transaction.isIncome ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.black, fontSize: 14)),
                const SizedBox(height: 4),
                Text(transaction.description, style: const TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$prefix₺${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountCard extends StatelessWidget {
  final double amount;
  final VoidCallback onTap;
  const _QuickAmountCard({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryDark, size: 22),
                const SizedBox(height: 8),
                Text('₺${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.black)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}