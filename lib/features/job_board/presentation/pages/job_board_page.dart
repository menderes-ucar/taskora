import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/job_posting_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/job_board_providers.dart';

class JobBoardPage extends ConsumerWidget {
  const JobBoardPage({super.key});

  void _showApplyDialog(BuildContext context, WidgetRef ref, JobPosting job) {
    final coverLetterController = TextEditingController();
    const double coinCost = 20;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${job.title} İlanına Başvur',
          style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bu ilana başvurmak $coinCost coin gerektirir. (Kaybetseniz bile coin iade edilmez)',
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coverLetterController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.black),
              decoration: const InputDecoration(
                hintText: 'Önyazınız / Kendinizi tanıtın',
                hintStyle: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final user = ref.read(authProvider).user;
              if (user == null) return;

              try {
                final service = ref.read(jobBoardServiceProvider);
                await service.applyToJobPosting(
                  jobPostingId: job.id,
                  freelancerId: user.id,
                  coverLetter: coverLetterController.text.trim(),
                  coinCost: coinCost,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Başvurunuz başarıyla iletildi! 🪙'),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  final cleanMsg = e.toString().replaceAll('Exception: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text(cleanMsg),
                    ),
                  );
                }
              }
            },
            child: const Text('Başvur ve Coin Öde', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobPostingsAsync = ref.watch(approvedJobPostingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'İş İlanları Panosu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: jobPostingsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz yayında bir iş ilanı yok.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            job.category,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${job.workType.label} • ${job.contractType.label}',
                      style: const TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${job.salaryInfo ?? "Maaş Belirtilmedi"} | ${job.location ?? "Konum Yok"}',
                      style: const TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.black, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showApplyDialog(context, ref, job),
                        child: const Text(
                          'Başvur',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, _) => Center(
          child: Text('Hata: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}