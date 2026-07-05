import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../shared/data/mock_data.dart';
import '../../../messages/ui/pages/chat_detail_page.dart';
import '../logic/jobs_provider.dart';
import 'send_proposal_page.dart';

class JobDetailPage extends ConsumerWidget {
  final String jobId;

  const JobDetailPage({
    super.key,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsNotifier = ref.read(jobsProvider.notifier);
    final job = jobsNotifier.getById(jobId);

    if (job == null) {
      return const Scaffold(
        body: Center(
          child: Text('İş bulunamadı'),
        ),
      );
    }

    final employer = MockData.getUserById(job.employerId);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('İş Detayı'),
        backgroundColor: AppColors.primary,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              text: 'Teklif Ver',
              icon: Icons.send_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendProposalPage(
                      jobId: job.id,
                      jobTitle: job.title,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              text: 'Mesaj At',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailPage(
                      otherUserId: job.employerId,
                      otherUserName: employer?.name ?? 'İşveren',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _JobDetailHero(job: job),
          const SizedBox(height: 16),
          SectionCard(
            title: 'İş Açıklaması',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppChip(label: job.category),
                    AppChip(label: '${job.deliveryDays} gün'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'İş Bilgileri',
            child: Column(
              children: [
                _DetailRow(title: 'Kategori', value: job.category),
                _DetailRow(
                  title: 'Teslim Süresi',
                  value: '${job.deliveryDays} gün',
                ),
                _DetailRow(
                  title: 'Bütçe',
                  value: '₺${job.budget.toStringAsFixed(0)}',
                  isAccent: true,
                  noBottomPadding: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Neden Bu İşe Teklif Vermelisin?',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Bu ilana teklif vererek doğrudan işverenle iletişime geçebilir, bütçeni ve teslim süreni kendi şartlarına göre sunabilirsin.',
                style: TextStyle(
                  height: 1.5,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobDetailHero extends StatelessWidget {
  final dynamic job;

  const _JobDetailHero({
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JOB OVERVIEW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            job.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroInfoChip(
                icon: Icons.payments_outlined,
                text: '₺${job.budget.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 10),
              _HeroInfoChip(
                icon: Icons.schedule_rounded,
                text: '${job.deliveryDays} gün',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isAccent;
  final bool noBottomPadding;

  const _DetailRow({
    required this.title,
    required this.value,
    this.isAccent = false,
    this.noBottomPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: noBottomPadding ? 0 : 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isAccent ? AppColors.primaryDark : AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}