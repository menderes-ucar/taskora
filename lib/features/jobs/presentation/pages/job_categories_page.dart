import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/providers/job_provider.dart';
import 'job_list_page.dart';

class JobCategoriesPage extends ConsumerWidget {
  const JobCategoriesPage({super.key});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      title: 'Grafik & Tasarım',
      categoryValue: 'Grafik Tasarım',
      icon: Icons.brush_rounded,
      color: Color(0xFFFF2A54),
    ),
    _CategoryItem(
      title: 'Sosyal Medya',
      categoryValue: 'Sosyal Medya',
      icon: Icons.ads_click_rounded,
      color: Color(0xFFFFB800),
    ),
    _CategoryItem(
      title: 'Yazı & Çeviri',
      categoryValue: 'Yazı Çeviri',
      icon: Icons.edit_rounded,
      color: Color(0xFF00F0FF),
    ),
    _CategoryItem(
      title: 'Video & Animasyon',
      categoryValue: 'Video',
      icon: Icons.videocam_rounded,
      color: Color(0xFF00FF66),
    ),
    _CategoryItem(
      title: 'Ses & Müzik',
      categoryValue: 'Ses Müzik',
      icon: Icons.headphones_rounded,
      color: Color(0xFF9D4EDD),
    ),
    _CategoryItem(
      title: 'Yazılım & Teknoloji',
      categoryValue: 'Yazılım',
      icon: Icons.code_rounded,
      color: Color(0xFFFF6B00),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openJobs = ref.watch(openJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Kategoriler',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF0E2238), Color(0xFF103847), Color(0xFF0BA99C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KATEGORİLER', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Yetenek alanını seç, sana uygun işleri hemen keşfet.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final item = _categories[index];
              final count = openJobs.where((job) => job.category == item.categoryValue).length;

              return Container(
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobListPage(
                          initialCategory: item.categoryValue,
                          pageTitle: item.title,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(item.icon, color: Colors.black, size: 28),
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$count aktif ilan',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.65),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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

  const _CategoryItem({
    required this.title,
    required this.categoryValue,
    required this.icon,
    required this.color,
  });
}