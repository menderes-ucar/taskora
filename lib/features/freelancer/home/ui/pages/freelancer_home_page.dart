import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_dashboard_widgets.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../../shared/models/proposal_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../employer/contracts/logic/contracts_provider.dart';
import '../../../../employer/jobs/ui/pages/job_list_page.dart';
import '../../../contracts/ui/pages/my_active_jobs_page.dart';
import '../../../jobs/ui/logic/jobs_provider.dart';
import '../../../notification/ui/widgets/notification_bell_button.dart';
import '../../../proposals/logic/proposals_provider.dart';
import '../../../proposals/ui/pages/my_proposals_page.dart';

class FreelancerHomePage extends ConsumerWidget {
  final String userName;

  const FreelancerHomePage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(openJobsProvider);
    final proposalsAsync = ref.watch(proposalsProvider);
    final contracts = ref.watch(contractsProvider);

    return jobsAsync.when(
      data: (jobs) {
        return proposalsAsync.when(
          data: (proposals) {
            final myProposals = currentUser == null
                ? 0
                : proposals
                .where((p) => p.freelancerId == currentUser.id)
                .length;

            final acceptedJobs = currentUser == null
                ? 0
                : proposals
                .where(
                  (p) =>
              p.freelancerId == currentUser.id &&
                  p.status.name == 'accepted',
            )
                .length;

            final activeContracts = currentUser == null
                ? 0
                : contracts
                .where(
                  (c) =>
              c.freelancerId == currentUser.id &&
                  c.status.name != 'completed',
            )
                .length;

            final recentJobs = jobs.take(3).toList();

            return Scaffold(
              backgroundColor: AppColors.primary,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: const Text(
                  'Freelancer',
                  style: TextStyle(color: Colors.white),
                ),
                actions: const [
                  NotificationBellButton(),
                ],
              ),
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _FreelancerHero(
                      userName: userName,
                      jobCount: jobs.length,
                      proposalCount: myProposals,
                      activeContracts: activeContracts,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppSummaryCard(
                            title: 'İlanlar',
                            value: '${jobs.length}',
                            icon: Icons.work_outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppSummaryCard(
                            title: 'Teklifler',
                            value: '$myProposals',
                            icon: Icons.send_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppWideSummaryCard(
                      title: 'Aktif İşler',
                      value: '$activeContracts',
                      subtitle: 'Devam eden işler',
                      icon: Icons.task_alt,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyActiveJobsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    AppWideSummaryCard(
                      title: 'Kabul Edilen',
                      value: '$acceptedJobs',
                      subtitle: 'Onaylanan tekliflerin',
                      icon: Icons.verified_rounded,
                      accentColor: AppColors.success,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyProposalsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const AppSectionHeader(
                      title: 'Hızlı İşlemler',
                      subtitle: 'Tek dokunuşla ilerle',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppActionCard(
                            icon: Icons.search,
                            title: 'İş Bul',
                            subtitle: 'Yeni ilanlara bak',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JobsListPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppActionCard(
                            icon: Icons.description,
                            title: 'Tekliflerim',
                            subtitle: 'Durumunu kontrol et',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyProposalsPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppWideActionCard(
                      icon: Icons.task_outlined,
                      title: 'Aktif İşlerim',
                      subtitle: 'Devam eden işlerini görüntüle',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyActiveJobsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const AppSectionHeader(
                      title: 'Senin İçin İşler',
                      subtitle: 'Öne çıkan ilanlar',
                    ),
                    const SizedBox(height: 12),
                    if (recentJobs.isEmpty)
                      const _EmptyMiniCard(
                        title: 'İlan yok',
                        subtitle: 'Yeni ilanlar yakında',
                      )
                    else
                      ...recentJobs.map(
                            (job) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FeaturedJobCard(job: job),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text('Hata: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Hata: $error')),
      ),
    );
  }
}

class _FreelancerHero extends StatelessWidget {
  final String userName;
  final int jobCount;
  final int proposalCount;
  final int activeContracts;

  const _FreelancerHero({
    required this.userName,
    required this.jobCount,
    required this.proposalCount,
    required this.activeContracts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TASKORA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Merhaba $userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bugün yeni fırsatlar seni bekliyor',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(value: '$jobCount', label: 'İlan'),
              _HeroStat(value: '$proposalCount', label: 'Teklif'),
              _HeroStat(value: '$activeContracts', label: 'Aktif'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedJobCard extends StatelessWidget {
  final JobModel job;

  const _FeaturedJobCard({
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.category,
                  style: const TextStyle(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₺${job.budget.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMiniCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyMiniCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}