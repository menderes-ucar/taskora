import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../shared/enums/job_status.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../freelancer/jobs/ui/logic/jobs_provider.dart';
import '../../../../settings/ui/pages/settings_page.dart';
import '../../../../wallet/ui/wallet_page.dart';

class EmployerProfilePage extends ConsumerWidget {
  const EmployerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(jobsProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: const Center(
          child: Text('Kullanıcı bulunamadı'),
        ),
      );
    }

    return jobsAsync.when(
      data: (jobs) {
        final myJobs = jobs.where((job) => job.employerId == user.id).toList();
        final openCount =
            myJobs.where((job) => job.status == JobStatus.open).length;
        final inProgressCount =
            myJobs.where((job) => job.status == JobStatus.inProgress).length;
        final completedCount =
            myJobs.where((job) => job.status == JobStatus.completed).length;

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            scrolledUnderElevation: 0,
            title: const Text('Profil'),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        size: 38,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.title ?? '-',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.bio ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.grey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            title: 'Puan',
                            value: '${user.rating ?? 0}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            title: 'Yorum',
                            value: '${user.reviewCount ?? 0}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            title: 'İş',
                            value: '${user.completedJobs ?? 0}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'İlan İstatistikleri',
                child: Row(
                  children: [
                    Expanded(
                      child: _ColoredStatBox(
                        title: 'Açık',
                        value: '$openCount',
                        icon: Icons.campaign_outlined,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ColoredStatBox(
                        title: 'Devam',
                        value: '$inProgressCount',
                        icon: Icons.handshake_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ColoredStatBox(
                        title: 'Biten',
                        value: '$completedCount',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Uzmanlık Alanları',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (user.skills ?? [])
                      .map((skill) => AppChip(label: skill))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Cüzdanım',
                icon: Icons.account_balance_wallet_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'Ayarlar',
                icon: Icons.settings_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
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
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ColoredStatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ColoredStatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}