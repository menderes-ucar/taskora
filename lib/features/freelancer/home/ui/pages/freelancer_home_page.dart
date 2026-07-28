import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../contracts/logic/contracts_provider.dart';
import '../../../../contracts/presentation/pages/my_active_jobs_page.dart';
import '../../../../jobs/domain/providers/job_provider.dart';
import '../../../../jobs/presentation/pages/job_categories_page.dart';
import '../../../../notification/presentation/widgets/notification_bell_button.dart';
import '../../../proposals/providers/proposals_provider.dart';
import '../../../proposals/ui/pages/my_proposals_page.dart';

class FreelancerHomePage extends ConsumerWidget {
  final String userName;

  const FreelancerHomePage({
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

    // 🚀 ZAMAN AŞIMINA SEBEP OLAN ref.listen DÖNGÜLERİ KALDIRILDI!

    final List<JobModel> jobs = ref.watch(openJobsProvider);
    final proposalsAsync = ref.watch(proposalsProvider);
    final contractsAsync = ref.watch(contractsProvider);

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

    return proposalsAsync.when(
      data: (proposals) => contractsAsync.when(
        data: (contracts) {
          final myProposals = proposals
              .where((p) => p.freelancerId == currentUser.id)
              .length;

          final acceptedJobs = proposals
              .where(
                (p) =>
            p.freelancerId == currentUser.id &&
                (p.status == ProposalStatus.accepted ||
                    p.status.name == 'accepted'),
          )
              .length;

          final activeContracts = contracts.where((c) {
            if (c.freelancerId != currentUser.id) return false;
            final statusName = c.status.name.toLowerCase();
            return statusName != 'completed' &&
                statusName != 'cancelled' &&
                statusName != 'rejected';
          }).length;

          return Scaffold(
            backgroundColor: AppColors.primary,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              titleSpacing: 16,
              title: const Row(
                children: [
                  Icon(Icons.person_pin_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Freelancer Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                ref.invalidate(proposalsProvider);
                ref.invalidate(contractsProvider);
                ref.invalidate(jobsProvider);
              },
              child: ListView(
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
                          Color(0xFF0BA99C),
                        ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba $userName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${jobs.length} yeni ilan yayınlandı • $myProposals aktif teklif',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridStat(
                          'İlan Havuzu',
                          '${jobs.length}',
                          Icons.work_outline_rounded,
                          AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildGridStat(
                          'Tekliflerim',
                          '$myProposals',
                          Icons.send_rounded,
                          AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyActiveJobsPage(),
                            ),
                          ),
                          child: _buildGridStat(
                            'Aktif İşler',
                            '$activeContracts',
                            Icons.task_alt_rounded,
                            AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildGridStat(
                          'Kabul Edilen',
                          '$acceptedJobs',
                          Icons.verified_rounded,
                          AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Hızlı İşlemler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    Icons.search_rounded,
                    'İş Bul',
                    'Kategorilere göre ilanlara göz at',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JobCategoriesPage(),
                      ),
                    ),
                  ),
                  _buildActionTile(
                    Icons.description_outlined,
                    'Tekliflerim',
                    'Durumları kontrol et',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyProposalsPage(),
                      ),
                    ),
                  ),
                  _buildActionTile(
                    Icons.task_alt_rounded,
                    'Aktif İşlerim',
                    'Süreçleri takip et',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyActiveJobsPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Text(
              'Bağlantı yenileniyor... ($err)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      loading: () => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text(
            'Bağlantı yenileniyor... ($err)',
            style: const TextStyle(color: Colors.white),
          ),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 14),
          Text(
            val,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          color: AppColors.primaryDark.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.black,
          ),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}