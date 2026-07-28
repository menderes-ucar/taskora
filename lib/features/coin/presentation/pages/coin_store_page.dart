import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../wallet/presentation/pages/add_funds_page.dart';
import '../../../wallet/providers/wallet_provider.dart';
import '../../data/services/coin_service.dart';

class CoinPackage {
  final String id;
  final String title;
  final int coins;
  final double priceTL;
  final bool isPopular;

  const CoinPackage({
    required this.id,
    required this.title,
    required this.coins,
    required this.priceTL,
    this.isPopular = false,
  });
}

class CoinStorePage extends ConsumerStatefulWidget {
  const CoinStorePage({super.key});

  @override
  ConsumerState<CoinStorePage> createState() => _CoinStorePageState();
}

class _CoinStorePageState extends ConsumerState<CoinStorePage> {
  bool _isLoading = false;

  static const List<CoinPackage> _packages = [
    CoinPackage(
      id: 'starter',
      title: 'Başlangıç Paketi',
      coins: 20,
      priceTL: 50.0,
    ),
    CoinPackage(
      id: 'pro',
      title: 'Avantajlı Paket',
      coins: 50,
      priceTL: 100.0,
      isPopular: true,
    ),
    CoinPackage(
      id: 'ultra',
      title: 'Pro Freelancer',
      coins: 120,
      priceTL: 200.0,
    ),
  ];

  Future<void> _buyPackage(CoinPackage package) async {
    final userId = ref.read(authProvider).user?.id ??
        Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Oturum bulunamadı. Lütfen tekrar giriş yapın.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final coinService = SupabaseCoinService();
      await coinService.buyCoinPackage(
        userId: userId,
        coinAmount: package.coins,
        priceTL: package.priceTL,
        packageName: package.title,
      );

      ref.invalidate(walletProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('🎉 Tebrikler! ${package.coins} Coin hesabınıza tanımlandı.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(e.toString().replaceAll('Exception: ', '')),
            action: SnackBarAction(
              label: 'Para Yükle',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddFundsPage(userId: userId),
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final currentBalance = walletAsync.asData?.value.balance ?? 0.0;
    final currentUserId = ref.watch(authProvider).user?.id ??
        Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Coin Mağazası',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bakiyem Kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryDark.withValues(alpha: 0.20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kullanılabilir TL Bakiyeniz',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺${currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (currentUserId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddFundsPage(userId: currentUserId),
                          ),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'TL Yükle',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'İlan Teklifleri İçin Coin Paketleri',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),

            // Paket Kartları
            ..._packages.map((pkg) => _buildPackageCard(pkg, currentBalance)),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(CoinPackage pkg, double currentBalance) {
    final bool canAfford = currentBalance >= pkg.priceTL;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pkg.isPopular
              ? AppColors.primaryDark
              : AppColors.primaryDark.withValues(alpha: 0.20),
          width: pkg.isPopular ? 2 : 1,
        ),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFB800),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pkg.title,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pkg.isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'En Popüler',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pkg.coins} Coin',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? AppColors.primaryDark : Colors.grey.shade300,
              foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
              elevation: 0,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : () => _buyPackage(pkg),
            child: Text(
              '₺${pkg.priceTL.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}