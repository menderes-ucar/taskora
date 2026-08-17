import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/job_posting_model.dart';
import '../../../job_board/presentation/providers/job_board_providers.dart';

class AdminJobPostingsPage extends ConsumerWidget {
  const AdminJobPostingsPage({super.key});

  Future<void> _approvePosting(BuildContext context, WidgetRef ref, JobPosting posting) async {
    try {
      final service = ref.read(jobBoardServiceProvider);
      await service.approveJobPosting(posting.id);

      // 🚀 ZORLA YENİLE: Onaylanan ilanı admin listesinden anında düşürür
      ref.invalidate(pendingJobPostingsStreamProvider);
      ref.invalidate(approvedJobPostingsStreamProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            content: Text(
              '\"${posting.title}\" onaylandı ✓',
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 2),
            content: Text('Hata: $e', style: const TextStyle(color: AppColors.white)),
          ),
        );
      }
    }
  }

  Future<void> _rejectPosting(BuildContext context, WidgetRef ref, JobPosting posting, String reason) async {
    try {
      final service = ref.read(jobBoardServiceProvider);
      await service.rejectJobPosting(
        jobPostingId: posting.id,
        reason: reason.isNotEmpty ? reason : null,
      );

      // 🚀 ZORLA YENİLE: Reddedilen ilanı listeden anında kaldırır
      ref.invalidate(pendingJobPostingsStreamProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 2),
            content: Text(
              '\"${posting.title}\" reddedildi',
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 2),
            content: Text('Hata: $e', style: const TextStyle(color: AppColors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 CANLI STREAM DİNLEYİCİ
    final pendingJobsAsync = ref.watch(pendingJobPostingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        title: const Text(
          'Kariyer İlan Onayları',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          pendingJobsAsync.maybeWhen(
            data: (jobs) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Bekleyen: ${jobs.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: pendingJobsAsync.when(
        data: (pendingPostings) {
          if (pendingPostings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Onay Bekleyen İlan Yok',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tüm kariyer ilanları incelenmiş',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceCard,
            onRefresh: () async {
              ref.invalidate(pendingJobPostingsStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingPostings.length,
              itemBuilder: (context, index) {
                final posting = pendingPostings[index];
                return _buildPostingCard(context, ref, posting);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Hata: $err', style: const TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }

  Widget _buildPostingCard(BuildContext context, WidgetRef ref, JobPosting posting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      posting.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      posting.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning, width: 0.5),
                ),
                child: const Text(
                  'Beklemede',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            posting.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildDetailTag(posting.workType.label),
              _buildDetailTag(posting.contractType.label),
              if (posting.salaryInfo != null) _buildDetailTag(posting.salaryInfo!),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approvePosting(context, ref, posting),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Onayla',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context, ref, posting),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reddet',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary, width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, JobPosting posting) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'İlanı Reddet',
          style: TextStyle(color: AppColors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İlan: ${posting.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reddetme Sebebi (İsteğe Bağlı)',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: 'Reddetme sebebini yazınız...',
                hintStyle: const TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: AppColors.dark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectPosting(
                context,
                ref,
                posting,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(
              'Reddet',
              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}