import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/helpers/job_category_helper.dart';
import '../../../../shared/models/job_model.dart';
import '../../domain/providers/job_filter_provider.dart';
import 'job_detail_page.dart';

class JobListPage extends ConsumerWidget {
  final String? initialCategory;
  final String? pageTitle;

  const JobListPage({
    super.key,
    this.initialCategory,
    this.pageTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(jobsFilterProvider.notifier).setCategory(initialCategory);
      });
    }

    final filteredJobs = ref.watch(filteredJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          pageTitle ?? 'Mevcut İlanlar',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: filteredJobs.isEmpty
          ? const Center(
        child: Text(
          'İlan Bulunamadı',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Yan yana 2 ilan
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62, // Kart oran ayarı
        ),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          return _JobGridCard(job: filteredJobs[index]);
        },
      ),
    );
  }
}

class _JobGridCard extends StatefulWidget {
  final JobModel job;
  const _JobGridCard({required this.job});

  @override
  State<_JobGridCard> createState() => _JobGridCardState();
}

class _JobGridCardState extends State<_JobGridCard> {
  String _employerName = 'İşveren';
  bool _isLoadingEmployer = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployerInfo();
  }

  Future<void> _fetchEmployerInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', widget.job.employerId)
          .maybeSingle();

      if (response != null && response['name'] != null && mounted) {
        setState(() {
          _employerName = response['name'].toString();
          _isLoadingEmployer = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingEmployer = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEmployer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int requiredCoins = JobCategoryHelper.getCoinCostByCategory(widget.job.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailPage(jobId: widget.job.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori & Coin Bedeli Rozetleri
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.job.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$requiredCoins Coin',
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // İlan Başlığı
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // İlan Açıklaması
                Text(
                  widget.job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // İşveren İsmi
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _isLoadingEmployer ? 'Yükleniyor...' : _employerName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bütçe ve Süre
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₺${widget.job.budgetMin.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      widget.job.duration,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Detay / Teklif Butonu
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JobDetailPage(jobId: widget.job.id)),
                    ),
                    child: Text(
                      'İncele ',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}