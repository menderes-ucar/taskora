import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/job_board_enums.dart';
import '../../../../shared/models/job_posting_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/job_board_providers.dart';
import 'create_job_posting_page.dart';

class EmployerJobBoardPage extends ConsumerStatefulWidget {
  const EmployerJobBoardPage({super.key});

  @override
  ConsumerState<EmployerJobBoardPage> createState() => _EmployerJobBoardPageState();
}

class _EmployerJobBoardPageState extends ConsumerState<EmployerJobBoardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.dark,
        body: Center(child: Text('Oturum Açın', style: TextStyle(color: AppColors.white))),
      );
    }

    final myJobsAsync = ref.watch(employerJobPostingsStreamProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'İlan Yönetim Paneli',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Yayındakiler'),
            Tab(text: 'Onay Bekleyenler'),
            Tab(text: 'Geçmiş / İptal'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateJobPostingPage(employerId: user.id),
          ),
        ),
        icon: const Icon(Icons.add, color: AppColors.black),
        label: const Text(
          'Yeni İlan Aç',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: myJobsAsync.when(
        data: (jobs) {
          // 🚀 SEKMELERE GÖRE KESİN AYRIM
          final approvedJobs = jobs.where((j) => j.status == PostingStatus.approved).toList();
          final pendingJobs = jobs.where((j) => j.status == PostingStatus.pending).toList();
          final pastJobs = jobs.where((j) => j.status == PostingStatus.closed || j.status == PostingStatus.rejected).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildJobList(approvedJobs, 'Yayında olan aktif bir ilanınız bulunmuyor.'),
              _buildJobList(pendingJobs, 'Admin onayı bekleyen ilanınız yok.'),
              _buildJobList(pastJobs, 'Geçmiş veya kapatılmış ilanınız bulunmuyor.'),
            ],
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

  Widget _buildJobList(List<JobPosting> jobs, String emptyText) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined, size: 54, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(emptyText, style: const TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: jobs.length,
      itemBuilder: (ctx, idx) {
        final job = jobs[idx];
        return _buildJobItemCard(job);
      },
    );
  }

  Widget _buildJobItemCard(JobPosting job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _buildStatusBadge(job.status),
              const SizedBox(width: 8),
              Text(
                '${job.workType.label} • ${job.contractType.label}',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.description,
                  style: const TextStyle(color: AppColors.offWhite, fontSize: 13, height: 1.4),
                ),
                const Divider(height: 24, color: AppColors.border),
                const Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Gelen Başvurular',
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ApplicationsList(jobPostingId: job.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PostingStatus status) {
    Color bg = AppColors.warning;
    if (status == PostingStatus.approved) bg = AppColors.success;
    if (status == PostingStatus.rejected) bg = AppColors.danger;
    if (status == PostingStatus.closed) bg = AppColors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg, width: 0.8),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ApplicationsList extends ConsumerWidget {
  final String jobPostingId;
  const _ApplicationsList({required this.jobPostingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(jobApplicationsStreamProvider(jobPostingId));

    return appsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Henüz bu ilana başvuran olmadı.', style: TextStyle(color: AppColors.grey, fontSize: 12)),
          );
        }

        return Column(
          children: apps.map((app) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
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
                    children: [
                      Text(
                        'Aday ID: ${app.freelancerId.substring(0, 8)}...',
                        style: const TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        app.status.label,
                        style: TextStyle(
                          color: Color(int.parse(app.status.colorCode.replaceAll('#', '0xFF'))),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Önyazı: ${app.coverLetter}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  if (app.status == ApplicationStatus.pending) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () async {
                            final service = ref.read(jobBoardServiceProvider);
                            await service.updateApplicationStatus(
                              applicationId: app.id,
                              newStatus: ApplicationStatus.rejected,
                            );
                          },
                          child: const Text('Reddet', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () async {
                            final service = ref.read(jobBoardServiceProvider);
                            await service.updateApplicationStatus(
                              applicationId: app.id,
                              newStatus: ApplicationStatus.accepted,
                            );
                          },
                          child: const Text('Kabul Et', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Text('Hata: $err', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
    );
  }
}