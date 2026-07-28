import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/enums/contract_status.dart';
import '../../../../../shared/enums/job_status.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../contracts/logic/contracts_provider.dart';
import '../../../../contracts/presentation/pages/my_active_projects_page.dart';
import '../../../../freelancer/proposals/providers/proposals_provider.dart';
import '../../../../jobs/domain/providers/job_provider.dart';
import '../../../../jobs/presentation/pages/my_pages_job.dart';
import '../../../../jobs/presentation/pages/received_proposals_page.dart';
import '../../../../notification/domain/providers/notification_provider.dart';
import '../../../../notification/presentation/widgets/notification_bell_button.dart';

class EmployerHomePage extends ConsumerWidget {
  final String userName;

  const EmployerHomePage({
    super.key,
    required this.userName,
  });

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Çıkış Yap',
            style: TextStyle(
                color: AppColors.black, fontWeight: FontWeight.bold)),
        content:
        const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, RouteNames.login, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(jobsProvider);
    final proposalsAsync = ref.watch(proposalsProvider);
    // 🚀 1. KONTRATLAR CANLI OLARAK DİNLENİYOR (Otomatik Güncelleme İçin Şart)
    final contractsAsync = ref.watch(contractsProvider);

    final unreadNotificationCount =
    ref.watch(unreadNotificationCountProvider);

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text('Kullanıcı bulunamadı',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.business_center_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text('Ana Sayfa',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          const NotificationBellButton(),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _handleLogout(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        backgroundColor: Colors.white,
        onRefresh: () async {
          // 🚀 Manuel Aşağı Çekip Yenileme
          await Future.wait([
            ref.read(jobsProvider.notifier).refreshJobs(),
            ref.read(proposalsProvider.notifier).refreshProposals(),
            ref.read(contractsProvider.notifier).refreshContracts(),
          ]);
        },
        child: jobsAsync.when(
          data: (jobs) => proposalsAsync.when(
            data: (proposals) => contractsAsync.when(
              data: (contracts) {
                final myJobs = jobs
                    .where((job) => job.employerId == currentUser.id)
                    .toList();
                final myJobIds = myJobs.map((job) => job.id).toSet();
                final receivedProposals = proposals
                    .where((proposal) => myJobIds.contains(proposal.jobId))
                    .toList();

                // 🚀 İşverene ait tüm sözleşmeler
                final myContracts = contracts
                    .where((c) => c.employerId == currentUser.id)
                    .toList();

                final openJobs =
                    myJobs.where((job) => job.status == JobStatus.open).length;

                // 🚀 2. DÜZELTME: Aktif Projeler ve Tamamlananlar doğrudan Kontratlar üzerinden hesaplanır
                final inProgressJobs = myContracts.where((c) {
                  final statusName = c.status.name.toLowerCase();
                  return statusName != 'completed' &&
                      statusName != 'cancelled' &&
                      statusName != 'rejected';
                }).length;

                final completedJobs = myContracts.where((c) {
                  return c.status == ContractStatus.completed ||
                      c.status.name.toLowerCase() == 'completed';
                }).length;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0E2238),
                            Color(0xFF103847),
                            Color(0xFF0BA99C)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Merhaba $userName 👋',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20)),
                          const SizedBox(height: 6),
                          Text(
                              '$openJobs ilan • ${receivedProposals.length} teklif • $unreadNotificationCount yeni bildirim',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: _buildGridStat('Yayındaki', '$openJobs',
                                Icons.campaign_rounded, AppColors.primaryDark)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _buildGridStat(
                                'Teklifler',
                                '${receivedProposals.length}',
                                Icons.local_offer_rounded,
                                AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _buildGridStat(
                                'Aktif Proje',
                                '$inProgressJobs',
                                Icons.handshake_rounded,
                                AppColors.success)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _buildGridStat(
                                'Tamamlanan',
                                '$completedJobs',
                                Icons.task_alt_rounded,
                                AppColors.grey)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Hızlı İşlemler',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildActionTile(
                        Icons.campaign_rounded,
                        'İlanlarım',
                        'Tüm ilanlarını görüntüle',
                            () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyJobsPage()))),
                    _buildActionTile(
                        Icons.list_alt_rounded,
                        'Teklifler',
                        'Gelen teklifleri incele',
                            () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const ReceivedProposalsPage()))),
                    _buildActionTile(
                        Icons.assignment_rounded,
                        'Aktif Projeler',
                        'Süreçleri takip et',
                            () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const MyActiveProjectsPage()))),
                  ],
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              error: (err, _) => Center(
                  child: Text('Hata: $err',
                      style: const TextStyle(color: Colors.white))),
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
            error: (err, _) => Center(
                child: Text('Hata: $err',
                    style: const TextStyle(color: Colors.white))),
          ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (err, _) => Center(
              child: Text('Hata: $err',
                  style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildGridStat(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 14),
          Text(val,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.20)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: AppColors.black)),
        subtitle:
        Text(sub, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.primaryDark),
      ),
    );
  }
}