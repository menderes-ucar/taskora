import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/coin_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/coin_service.dart';
import '../../data/services/iap_coin_service.dart';

class CoinStorePage extends ConsumerStatefulWidget {
  const CoinStorePage({super.key});

  @override
  ConsumerState<CoinStorePage> createState() => _CoinStorePageState();
}

class _CoinStorePageState extends ConsumerState<CoinStorePage> {
  final IapCoinService _iap = IapCoinService();
  List<CoinPackage> _packages = const [];
  List<ProductDetails> _products = const [];
  bool _loading = true;
  String? _error;
  String? _buyingProductId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _iap.initialize(
        onPurchase: (purchase) async {
          final result = await _iap.verifyAndDeliver(purchase);
          if (!mounted) return;
          _showMessage(result.message, success: true);
        },
        onTerminalPurchase: (purchase) {
          if (!mounted) return;
          setState(() => _buyingProductId = null);
        },
      );

      final packages = await SupabaseCoinService().getActiveCoinPackages();
      final products = await _iap.loadProducts(packages);

      if (!mounted) return;
      setState(() {
        _packages = packages;
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  ProductDetails? _productFor(CoinPackage package) {
    for (final product in _products) {
      if (product.id == package.storeProductId) return product;
    }
    return null;
  }

  Future<void> _buy(CoinPackage package) async {
    final userId = ref.read(authProvider).user?.id ??
        Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      _showMessage('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      return;
    }

    final product = _productFor(package);
    if (product == null) {
      _showMessage('Bu paket mağazada henüz yapılandırılmamış.');
      return;
    }

    setState(() => _buyingProductId = package.storeProductId);

    try {
      await _iap.buy(package);
      // Result is delivered asynchronously by purchaseStream. Do not grant
      // coins or close the page here.
    } catch (e) {
      if (!mounted) return;
      setState(() => _buyingProductId = null);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.success : AppColors.danger,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_iap.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _bootstrap)
          : RefreshIndicator(
        onRefresh: _bootstrap,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            const Text(
              'Coin Paketleri',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (_packages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aktif coin paketi bulunamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else ...[
              if (_products.isEmpty) _buildStoreConfigurationWarning(),
              ..._packages.map(_buildPackageCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2238), Color(0xFF103847), Color(0xFF0BA99C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 30),
          SizedBox(height: 12),
          Text(
            'Güvenli Coin Satın Alma',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Ödemeler Google Play veya App Store üzerinden gerçekleşir. Coinler yalnızca doğrulanmış mağaza işlemi sonrasında hesabınıza eklenir.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreConfigurationWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB800).withValues(alpha: 0.45),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFFFB800)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Coin paketleri veritabanından geliyor ancak Google Play / App Store ürünleri henüz bu cihazda bulunamadı. Satın alma butonu, mağaza ürünü tanımlanınca aktifleşir.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(CoinPackage package) {
    final product = _productFor(package);
    final hasStoreProductId = package.storeProductId.trim().isNotEmpty;
    final isBuying = _buyingProductId == package.storeProductId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: package.sortOrder == 20
              ? AppColors.primaryDark
              : AppColors.primaryDark.withValues(alpha: 0.20),
          width: package.sortOrder == 20 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB800), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${package.coinAmount} Coin',
                  style: const TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  product?.price ?? '₺${package.priceTry.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: !hasStoreProductId || product == null || _buyingProductId != null
                ? null
                : () => _buy(package),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isBuying
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
              product != null ? 'Satın Al' : 'Hazır değil',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
