import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/proposal_model.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../jobs/domain/providers/job_provider.dart';
import '../../providers/proposals_provider.dart';

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
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Tekliflerim',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: myProposals.isEmpty
              ? const EmptyState(
            icon: Icons.send_rounded,
            title: 'Henüz teklif göndermedin',
            subtitle: 'İlgini çeken ilanlara teklif verdiğinde burada listelenecek.',
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: myProposals.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TopSummary(
                    title: 'Gönderilen Teklifler',
                    subtitle: '${myProposals.length} teklifin var. Durumlarını buradan anlık takip edebilirsin kanka.',
                  ),
                );
              }

              final proposal = myProposals[index - 1];
              final relatedJob = proposal.jobId.trim().isEmpty ? null : jobsNotifier.getById(proposal.jobId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MyProposalCard(
                  proposal: proposal,
                  jobTitle: relatedJob?.title ?? 'İlan Başlığı',
                  jobCategory: relatedJob?.category,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: Text('Hata: $error', style: const TextStyle(color: Colors.white))),
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
      case ProposalStatus.pending: return AppColors.warning;
      case ProposalStatus.accepted: return AppColors.success;
      case ProposalStatus.rejected: return AppColors.danger;
    }
  }

  String _statusText() {
    switch (proposal.status) {
      case ProposalStatus.pending: return 'Beklemede';
      case ProposalStatus.accepted: return 'Kabul Edildi';
      case ProposalStatus.rejected: return 'Reddedildi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  _statusText(),
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (jobCategory != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(jobCategory!, style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text('${proposal.deliveryDays} gün süre', style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              proposal.coverLetter,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.grey, height: 1.45, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: AppColors.grey),
                  SizedBox(width: 6),
                  Text('Teklif Tutarı', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Text(
                '₺${proposal.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.success),
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

  const _TopSummary({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            color: AppColors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, height: 1.4, fontSize: 13)),
        ],
      ),
    );
  }
}