import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskora/shared/enums/job_status.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_dashboard_widgets.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../../shared/models/proposal_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../freelancer/jobs/ui/logic/jobs_provider.dart';
import '../../../../freelancer/notification/logic/notifications_provider.dart';
import '../../../../freelancer/notification/ui/widgets/notification_bell_button.dart';
import '../../../../freelancer/proposals/logic/proposals_provider.dart';
import '../../../contracts/logic/contracts_provider.dart';
import '../../../contracts/ui/pages/my_active_projects_page.dart';
import '../../../jobs/ui/pages/my_jobs_page.dart';
import '../../../jobs/ui/pages/received_proposals_page.dart';

class EmployerHomePage extends ConsumerWidget {
  final String userName;

  const EmployerHomePage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(jobsProvider);
    final proposalsAsync = ref.watch(proposalsProvider);
    final contracts = ref.watch(contractsProvider);

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text('Kullanıcı bulunamadı'),
        ),
      );
    }

    ref.watch(notificationsProvider);
    final unreadNotificationCount =
    ref.read(notificationsProvider.notifier).unreadCount(currentUser.id);

    return jobsAsync.when(
      data: (jobs) {
        return proposalsAsync.when(
          data: (proposals) {
            final myJobs = jobs
                .where((job) => job.employerId == currentUser.id)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final myJobIds = myJobs.map((job) => job.id).toSet();

            final receivedProposals = proposals
                .where((proposal) => myJobIds.contains(proposal.jobId))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final myContracts = contracts
                .where((contract) => contract.employerId == currentUser.id)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final openJobs =
                myJobs.where((job) => job.status == JobStatus.open).length;
            final inProgressJobs = myJobs
                .where((job) => job.status == JobStatus.inProgress)
                .length;
            final completedJobs = myJobs
                .where((job) => job.status == JobStatus.completed)
                .length;

            final recentJobs = myJobs.take(3).toList();
            final recentProposals = receivedProposals.take(3).toList();
            final recentContracts = myContracts.take(2).toList();

            return Scaffold(
              backgroundColor: AppColors.primary,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                scrolledUnderElevation: 0,
                titleSpacing: 16,
                title: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Employer Dashboard'),
                  ],
                ),
                actions: const [
                  NotificationBellButton(),
                  SizedBox(width: 6),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _EmployerPremiumHero(
                    userName: userName,
                    openJobs: openJobs,
                    proposalCount: receivedProposals.length,
                    inProgressJobs: inProgressJobs,
                    unreadNotificationCount: unreadNotificationCount,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: AppSummaryCard(
                          title: 'Yayındaki İlan',
                          value: '$openJobs',
                          icon: Icons.campaign_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppSummaryCard(
                          title: 'Gelen Teklif',
                          value: '${receivedProposals.length}',
                          icon: Icons.local_offer_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppSummaryCard(
                          title: 'Aktif Proje',
                          value: '$inProgressJobs',
                          icon: Icons.handshake_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppSummaryCard(
                          title: 'Tamamlanan',
                          value: '$completedJobs',
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const AppSectionHeader(
                    title: 'Hızlı İşlemler',
                    subtitle: 'İlan, teklif ve proje süreçlerini buradan yönet',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppActionCard(
                          icon: Icons.campaign_outlined,
                          title: 'İlanlarım',
                          subtitle: 'Tüm ilanlarını görüntüle ve düzenle',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyJobsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppActionCard(
                          icon: Icons.list_alt_outlined,
                          title: 'Teklifler',
                          subtitle: 'Gelen teklifleri inceleyip karar ver',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReceivedProposalsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppWideActionCard(
                    icon: Icons.assignment_outlined,
                    title: 'Aktif Projeler',
                    subtitle: 'Devam eden projeleri aç ve süreci takip et',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyActiveProjectsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const AppSectionHeader(
                    title: 'Son Aktiviteler',
                    subtitle: 'En son ilanlar, teklifler ve proje hareketleri',
                  ),
                  const SizedBox(height: 12),
                  if (recentJobs.isNotEmpty) ...[
                    const _MiniBlockTitle(
                      title: 'Son İlanlar',
                      icon: Icons.work_outline_rounded,
                    ),
                    const SizedBox(height: 10),
                    ...recentJobs.map(
                          (job) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentJobCard(job: job),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (recentProposals.isNotEmpty) ...[
                    const _MiniBlockTitle(
                      title: 'Son Gelen Teklifler',
                      icon: Icons.local_offer_outlined,
                    ),
                    const SizedBox(height: 10),
                    ...recentProposals.map(
                          (proposal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentProposalCard(
                          freelancerName: proposal.freelancerName,
                          amount: proposal.amount,
                          deliveryDays: proposal.deliveryDays,
                          coverLetter: proposal.coverLetter,
                          statusName: proposal.status.name,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (recentContracts.isNotEmpty) ...[
                    const _MiniBlockTitle(
                      title: 'Sözleşme Hareketleri',
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 10),
                    ...recentContracts.map(
                          (contract) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentContractCard(
                          title: contract.jobTitle,
                          freelancerName: contract.freelancerName,
                          amount: contract.agreedAmount,
                          statusName: contract.status.name,
                        ),
                      ),
                    ),
                  ],
                  if (recentJobs.isEmpty &&
                      recentProposals.isEmpty &&
                      recentContracts.isEmpty)
                    const _EmptyDashboardCard(
                      title: 'Henüz hareket yok',
                      subtitle:
                      'İlan oluşturduğunda, teklifler geldikçe ve sözleşmeler başladıkça burada görünecek.',
                    ),
                ],
              ),
            );
          },
          loading: () => const Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(child: Text('Hata: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: Text('Hata: $error')),
      ),
    );
  }
}

class _EmployerPremiumHero extends StatelessWidget {
  final String userName;
  final int openJobs;
  final int proposalCount;
  final int inProgressJobs;
  final int unreadNotificationCount;

  const _EmployerPremiumHero({
    required this.userName,
    required this.openJobs,
    required this.proposalCount,
    required this.inProgressJobs,
    required this.unreadNotificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Merhaba $userName',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$openJobs ilan • $proposalCount teklif',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MiniBlockTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MiniBlockTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _RecentJobCard extends StatelessWidget {
  final JobModel job;

  const _RecentJobCard({
    required this.job,
  });

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return AppColors.primaryDark;
      case JobStatus.inProgress:
        return AppColors.warning;
      case JobStatus.completed:
        return AppColors.success;
      case JobStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(job.status);

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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    job.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₺${job.budget.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyDashboardCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.primaryDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentProposalCard extends StatelessWidget {
  final String freelancerName;
  final double amount;
  final int deliveryDays;
  final String coverLetter;
  final String statusName;

  const _RecentProposalCard({
    required this.freelancerName,
    required this.amount,
    required this.deliveryDays,
    required this.coverLetter,
    required this.statusName,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      case 'pending':
      default:
        return 'Beklemede';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(statusName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  freelancerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coverLetter,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(statusName),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$deliveryDays gün',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₺${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentContractCard extends StatelessWidget {
  final String title;
  final String freelancerName;
  final double amount;
  final String statusName;

  const _RecentContractCard({
    required this.title,
    required this.freelancerName,
    required this.amount,
    required this.statusName,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      case 'active':
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      case 'active':
      default:
        return 'Aktif';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(statusName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  freelancerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(statusName),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₺${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}