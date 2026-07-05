import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/proposal_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../freelancer/jobs/ui/logic/jobs_provider.dart';
import '../../logic/proposals_provider.dart';

class MyProposalsPage extends ConsumerWidget {
  const MyProposalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final allProposalsAsync = ref.watch(proposalsProvider);
    final jobsNotifier = ref.read(jobsProvider.notifier);

    return allProposalsAsync.when(
      data: (allProposals) {
        final myProposals = currentUser == null
            ? <ProposalModel>[]
            : allProposals
            .where((proposal) => proposal.freelancerId == currentUser.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tekliflerim'),
          ),
          body: myProposals.isEmpty
              ? const EmptyState(
            icon: Icons.send_outlined,
            title: 'Henüz teklif göndermedin',
            subtitle:
            'İlgini çeken ilanlara teklif verdiğinde burada listelenecek.',
          )
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _TopSummary(
                title: 'Gönderilen Teklifler',
                subtitle:
                '${myProposals.length} teklifin var. Durumlarını buradan takip edebilirsin.',
              ),
              const SizedBox(height: 16),
              ...List.generate(myProposals.length, (index) {
                final proposal = myProposals[index];
                final relatedJob = proposal.jobId.trim().isEmpty
                    ? null
                    : jobsNotifier.getById(proposal.jobId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MyProposalCard(
                    proposal: proposal,
                    jobTitle: relatedJob?.title ?? 'İlan',
                    jobCategory: relatedJob?.category,
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Tekliflerim'),
        ),
        body: Center(
          child: Text('Hata: $error'),
        ),
      ),
    );
  }
}

class _MyProposalCard extends StatelessWidget {
  final ProposalModel proposal;
  final String jobTitle;
  final String? jobCategory;

  const _MyProposalCard({
    required this.proposal,
    required this.jobTitle,
    this.jobCategory,
  });

  Color _statusColor() {
    switch (proposal.status) {
      case ProposalStatus.pending:
        return AppColors.warning;
      case ProposalStatus.accepted:
        return AppColors.success;
      case ProposalStatus.rejected:
        return AppColors.danger;
    }
  }

  String _statusText() {
    switch (proposal.status) {
      case ProposalStatus.pending:
        return 'Beklemede';
      case ProposalStatus.accepted:
        return 'Kabul Edildi';
      case ProposalStatus.rejected:
        return 'Reddedildi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
              ),
              AppChip(
                label: _statusText(),
                color: statusColor.withValues(alpha: 0.12),
                textColor: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (jobCategory != null) ...[
                AppChip(label: jobCategory!),
                const SizedBox(width: 8),
              ],
              AppChip(label: '${proposal.deliveryDays} gün'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              proposal.coverLetter,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _MetricLabel(
                title: 'Teklif Tutarı',
                icon: Icons.payments_outlined,
              ),
              const Spacer(),
              Text(
                '₺${proposal.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TopSummary({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MetricLabel({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.grey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}