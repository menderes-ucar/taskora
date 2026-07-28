import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/services/rating_service.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/models/portfolio_item_model.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../coin/data/services/coin_service.dart';
import '../../../../settings/presentation/pages/settings_page.dart';
import '../../../../wallet/presentation/pages/wallet_page.dart';
import '../../logic/portfolio_provider.dart';
import 'add_portfolio_page.dart';

class FreelancerProfilePage extends ConsumerStatefulWidget {
  const FreelancerProfilePage({super.key});

  @override
  ConsumerState<FreelancerProfilePage> createState() =>
      _FreelancerProfilePageState();
}

class _FreelancerProfilePageState
    extends ConsumerState<FreelancerProfilePage> {
  late SupabaseCoinService _coinService;
  late SupabaseRatingService _ratingService;
  int _userCoins = 0;
  double _userRating = 0.0;
  int _reviewCount = 0;
  bool _isLoadingCoins = true;

  @override
  void initState() {
    super.initState();
    _coinService = SupabaseCoinService(Supabase.instance.client);
    _ratingService = SupabaseRatingService(Supabase.instance.client);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isLoadingCoins = true);
    try {
      final coins = await _coinService.getUserCoinBalance(user.id);
      final ratingSummary = await _ratingService.getUserRatingSummary(user.id);

      if (mounted) {
        setState(() {
          _userCoins = coins;
          _userRating = ratingSummary.averageRating;
          _reviewCount = ratingSummary.totalReviews;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCoins = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Çıkış Yap',
            style:
            TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, RouteNames.login, (_) => false);
      }
    }
  }

  Widget _buildStat(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text('Kullanıcı bulunamadı',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }

    final portfolioState = ref.watch(portfolioProvider);
    final portfolio = portfolioState.valueOrNull
        ?.where((item) => item.freelancerId == user.id)
        .toList() ??
        const [];

    return Scaffold(
      backgroundColor: AppColors.primary, // 🚀 Turkuaz Arka Plan
      appBar: AppBar(
        title: const Text('Profilim',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await _loadUserData();
          ref.invalidate(portfolioProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // 🚀 Üst Kullanıcı & İstatistik Kartı
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0E2238),
                    Color(0xFF103847),
                    Color(0xFF0BA99C),
                  ],
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
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.title ?? 'Freelancer Uzmanı',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStat(
                              'Coin', _isLoadingCoins ? '...' : '$_userCoins')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStat(
                              'Puan',
                              _isLoadingCoins
                                  ? '...'
                                  : _userRating.toStringAsFixed(1))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStat('Yorum',
                              _isLoadingCoins ? '...' : '$_reviewCount')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🚀 Portföy Başlığı & Ekle Butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Portföyüm',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddPortfolioPage()),
                    );
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      color: Colors.white, size: 20),
                  label: const Text('Ekle',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🚀 Portföy Listesi veya Boş Durum
            if (portfolio.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.primaryDark.withValues(alpha: 0.20)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.work_outline, size: 40, color: AppColors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Henüz portföy projeniz yok',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'İlk projenizi ekleyerek müşterilerin dikkatini çekin.',
                      style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              ...portfolio.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PortfolioCard(item: item),
              )),

            const SizedBox(height: 24),

            // 🚀 Cüzdanım Butonu
            PrimaryButton(
              text: 'Cüzdanım',
              icon: Icons.account_balance_wallet_outlined,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletPage()),
                );
              },
            ),
            const SizedBox(height: 12),

            // 🚀 Ayarlar Butonu (Alt Seçenek)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                side: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.3)),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.settings_outlined,
                  color: AppColors.primaryDark),
              label: const Text(
                'Hesap ve Uygulama Ayarları',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioCard extends ConsumerWidget {
  final PortfolioItemModel item;
  const _PortfolioCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImages = item.imageUrls.isNotEmpty;

    Color statusColor;
    String statusLabel;
    if (item.status == 'approved') {
      statusColor = AppColors.success;
      statusLabel = 'Onaylandı';
    } else if (item.status == 'rejected') {
      statusColor = AppColors.danger;
      statusLabel = 'Reddedildi';
    } else {
      statusColor = AppColors.warning;
      statusLabel = 'İncelemede';
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImages)
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: PageView.builder(
                  itemCount: item.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      item.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.black,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: 110,
              decoration: const BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Center(
                child: Icon(Icons.layers_outlined,
                    color: AppColors.grey, size: 30),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.4,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          title: const Text('Silmek istiyor musun?'),
                          content: const Text('Bu işlem geri alınamaz.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('İptal'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sil',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(portfolioProvider.notifier)
                            .removePortfolioItem(item.id, item.freelancerId);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 18),
                    label: const Text(
                      'Sil',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}