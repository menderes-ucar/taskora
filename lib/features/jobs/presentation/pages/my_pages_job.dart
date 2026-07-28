import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../shared/enums/job_status.dart';
import '../../../../shared/models/job_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../freelancer/proposals/providers/proposals_provider.dart';
import '../../domain/providers/job_provider.dart';
import 'create_job_page.dart';
import 'received_proposals_page.dart';

class MyJobsPage extends ConsumerWidget {
  const MyJobsPage({super.key});

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return AppColors.success;
      case JobStatus.pending:
        return AppColors.warning;
      case JobStatus.inProgress:
        return AppColors.primaryDark;
      case JobStatus.completed:
        return AppColors.grey;
      case JobStatus.cancelled:
      case JobStatus.rejected:
        return AppColors.danger;
    }
  }

  String _getStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return 'YAYINDA';
      case JobStatus.pending:
        return 'ONAY BEKLİYOR';
      case JobStatus.inProgress:
        return 'DEVAM EDİYOR';
      case JobStatus.completed:
        return 'TAMAMLANDI';
      case JobStatus.cancelled:
        return 'İPTAL EDİLDİ';
      case JobStatus.rejected:
        return 'REDDEDİLDİ';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(jobsProvider);
    final proposalsAsync = ref.watch(proposalsProvider);

    return jobsAsync.when(
      data: (allJobs) {
        final myJobs = currentUser == null
            ? <JobModel>[]
            : allJobs.where((job) => job.employerId == currentUser.id).toList();

        final allProposals = proposalsAsync.valueOrNull ?? [];
        final pendingApprovalCount =
            myJobs.where((j) => j.status == JobStatus.pending).length;

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              'İlan Yönetim Paneli',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButton: myJobs.isNotEmpty
              ? FloatingActionButton.extended(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
            elevation: 4,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobPage()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni İlan Aç',
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
              : null,
          body: myJobs.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz hiç ilan oluşturmadınız.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İhtiyacınıza uygun projeyi oluşturun, onaylandıktan sonra yetenekli freelancerlardan teklif toplayın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'İlk İlanı Yayınla',
                    icon: Icons.add_circle_outline_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateJobPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0E2238),
                      Color(0xFF103847),
                      Color(0xFF0BA99C)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeaderStat('Toplam İlan', '${myJobs.length}'),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _buildHeaderStat('Onay Bekleyen', '$pendingApprovalCount'),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _buildHeaderStat(
                      'Gelen Teklif',
                      '${allProposals.where((p) => myJobs.any((j) => j.id == p.jobId)).length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tüm İlanlarınız',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              ...myJobs.map((job) {
                final jobProposals =
                allProposals.where((p) => p.jobId == job.id).toList();
                final statusColor = _getStatusColor(job.status);
                final statusText = _getStatusText(job.status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                        AppColors.primaryDark.withValues(alpha: 0.20)),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReceivedProposalsPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    job.category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    border: Border.all(
                                        color: statusColor
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                                height: 1, color: AppColors.offWhite),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: jobProposals.isNotEmpty
                                        ? AppColors.warning
                                        .withValues(alpha: 0.15)
                                        : AppColors.border
                                        .withValues(alpha: 0.3),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer_rounded,
                                        size: 15,
                                        color: jobProposals.isNotEmpty
                                            ? AppColors.warning
                                            : AppColors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${jobProposals.length} Teklif Alındı',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: jobProposals.isNotEmpty
                                              ? AppColors.black
                                              : AppColors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '₺${job.budgetMin.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child:
          Text('Hata: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}