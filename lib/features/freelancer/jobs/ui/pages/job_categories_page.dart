import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../employer/jobs/ui/pages/job_list_page.dart';
import '../logic/jobs_provider.dart';

class JobCategoriesPage extends ConsumerWidget {
  const JobCategoriesPage({super.key});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      title: 'Grafik & Tasarım',
      categoryValue: 'Grafik Tasarım',
      icon: Icons.brush_rounded,
      color: Color(0xFF3E63FF),
    ),
    _CategoryItem(
      title: 'İnternet\nReklamcılığı',
      categoryValue: 'Sosyal Medya',
      icon: Icons.ads_click_rounded,
      color: Color(0xFF32B8D8),
    ),
    _CategoryItem(
      title: 'Yazı & Çeviri',
      categoryValue: 'Yazı Çeviri',
      icon: Icons.edit_rounded,
      color: Color(0xFFFFC928),
      darkText: true,
    ),
    _CategoryItem(
      title: 'Video &\nAnimasyon',
      categoryValue: 'Video',
      icon: Icons.videocam_rounded,
      color: Color(0xFF32B44A),
    ),
    _CategoryItem(
      title: 'Ses & Müzik',
      categoryValue: 'Ses Müzik',
      icon: Icons.headphones_rounded,
      color: Color(0xFFFF596C),
    ),
    _CategoryItem(
      title: 'Yazılım &\nTeknoloji',
      categoryValue: 'Yazılım',
      icon: Icons.code_rounded,
      color: Color(0xFF2F3B52),
    ),
  ];

  int _countForCategory(List<JobModel> jobs, String categoryValue) {
    return jobs.where((job) => job.category == categoryValue).length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openJobsAsync = ref.watch(openJobsProvider);

    return openJobsAsync.when(
      data: (openJobs) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Kategoriler'),
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: Container(
            decoration: const BoxDecoration(),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const _CategoriesHero(),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.83,
                    ),
                    itemBuilder: (context, index) {
                      final item = _categories[index];
                      final count =
                      _countForCategory(openJobs, item.categoryValue);
                      final textColor =
                      item.darkText ? AppColors.black : Colors.white;
                      final subTextColor = item.darkText
                          ? AppColors.black.withOpacity(0.72)
                          : Colors.white70;

                      return InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobsListPage(
                                initialCategory: item.categoryValue,
                                pageTitle: item.title.replaceAll('\n', ' '),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withOpacity(0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -18,
                                right: -16,
                                child: Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -28,
                                left: -18,
                                child: Container(
                                  width: 116,
                                  height: 116,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: textColor,
                                      size: 30,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 21,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$count aktif ilan',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kategoriyi keşfet',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Hata: $error'),
        ),
      ),
    );
  }
}

class _CategoriesHero extends StatelessWidget {
  const _CategoriesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORIES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Yetenek alanını seç, sana uygun işleri daha hızlı keşfet.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final String categoryValue;
  final IconData icon;
  final Color color;
  final bool darkText;

  const _CategoryItem({
    required this.title,
    required this.categoryValue,
    required this.icon,
    required this.color,
    this.darkText = false,
  });
}