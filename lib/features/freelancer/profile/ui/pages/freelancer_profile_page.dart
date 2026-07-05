import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../shared/models/portfolio_item_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../wallet/ui/wallet_page.dart';
import '../../logic/portfolio_provider.dart';
import 'add_portfolio_page.dart';

class FreelancerProfilePage extends ConsumerWidget {
  const FreelancerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text('Kullanıcı bulunamadı'),
        ),
      );
    }

    final portfolio =
    ref.watch(portfolioProvider.notifier).getByFreelancer(user.id);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: AppColors.primary,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 38,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.title ?? '-',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.bio ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        title: 'Puan',
                        value: '${user.rating ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        title: 'Yorum',
                        value: '${user.reviewCount ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        title: 'İş',
                        value: '${user.completedJobs ?? 0}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Yeteneklerim',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (user.skills ?? [])
                  .map((skill) => AppChip(label: skill))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Portföyüm',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimaryButton(
                  text: 'Portföy Projesi Ekle',
                  icon: Icons.add_photo_alternate_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPortfolioPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                if (portfolio.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 48,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Henüz portföy yok',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'İlk projenizi ekleyerek başlayın',
                          style: TextStyle(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...portfolio.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PortfolioCard(item: item),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Cüzdanım',
            icon: Icons.account_balance_wallet_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WalletPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImages)
            SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: PageView.builder(
                  itemCount: item.imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = item.imageUrls[index];

                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: AppColors.black,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.white.withValues(alpha: 0.8),
                              size: 30,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: 130,
              decoration: const BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.layers_outlined,
                  color: AppColors.white.withValues(alpha: 0.8),
                  size: 34,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.category,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Silmek istiyor musun?'),
                          content: const Text('Bu işlem geri alınamaz.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        ref
                            .read(portfolioProvider.notifier)
                            .removePortfolioItem(item.id);
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Sil',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
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