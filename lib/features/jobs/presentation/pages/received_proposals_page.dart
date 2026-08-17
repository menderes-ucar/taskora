import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../../shared/models/proposal_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../employer/freelancers/ui/pages/freelancer_detail_page.dart';
import '../../../freelancer/proposals/providers/proposals_provider.dart';
import '../../domain/providers/job_provider.dart';

class ReceivedProposalsPage extends ConsumerWidget {
  const ReceivedProposalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(jobsProvider);
    final proposalsAsync = ref.watch(proposalsProvider);

    return jobsAsync.when(
      data: (jobs) {
        return proposalsAsync.when(
          data: (proposals) {
            final myJobs = currentUser == null
                ? <JobModel>[]
                : jobs.where((job) => job.employerId == currentUser.id).toList();

            final myJobIds = myJobs.map((job) => job.id).toSet();

            final receivedProposals = proposals
                .where((proposal) => myJobIds.contains(proposal.jobId))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Scaffold(
              backgroundColor: AppColors.primary,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
                title: const Text(
                  'Gelen Teklifler',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: receivedProposals.isEmpty
                  ? const Center(
                child: Text(
                  'Henüz gelen teklif yok',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: receivedProposals.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TopBanner(proposalCount: receivedProposals.length),
                    );
                  }

                  final proposal = receivedProposals[index - 1];
                  final relatedJob = myJobs.firstWhere(
                        (job) => job.id == proposal.jobId,
                  );

                  return _ReceivedProposalCard(
                    proposal: proposal,
                    relatedJob: relatedJob,
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

class _ReceivedProposalCard extends ConsumerWidget {
  final ProposalModel proposal;
  final JobModel relatedJob;

  const _ReceivedProposalCard({
    required this.proposal,
    required this.relatedJob,
  });

  Color _statusColor() {
    switch (proposal.status) {
      case ProposalStatus.pending:
        return AppColors.warning;

      case ProposalStatus.accepted:
        return AppColors.success;

      case ProposalStatus.rejected:
        return AppColors.danger;

      case ProposalStatus.withdrawn:
        return AppColors.grey;
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

      case ProposalStatus.withdrawn:
        return 'Geri Çekildi';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                child: Text(
                  proposal.freelancerName.isNotEmpty
                      ? proposal.freelancerName.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.freelancerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      relatedJob.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusText(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  relatedJob.category,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${proposal.deliveryDays} gün teslim',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              proposal.coverLetter,
              style: const TextStyle(color: AppColors.grey, height: 1.5, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: AppColors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Teklif Tutarı',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '₺${proposal.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            text: 'Profili İncele',
            icon: Icons.person_outline_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FreelancerDetailPage(
                  freelancerId: proposal.freelancerId,
                ),
              ),
            ),
          ),
          if (proposal.status == ProposalStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async => await ref
                        .read(proposalsProvider.notifier)
                        .updateProposalStatus(
                      proposal.id,
                      ProposalStatus.rejected,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Reddet',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Tek işlem: freelancer seçimi + işin inProgress olması
                        // + diğer uygun tekliflere %50 coin iadesi.
                        // Contract/Escrow bu akışın parçası değildir.
                        await ref
                            .read(proposalsProvider.notifier)
                            .selectProposalForJob(proposal.id);

                        ref.invalidate(proposalsProvider);
                        ref.invalidate(jobsProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Freelancer seçildi. Proje artık devam ediyor.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.danger,
                              content: Text('Freelancer seçilemedi: $e'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Kabul Et', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  final int proposalCount;

  const _TopBanner({required this.proposalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2238), Color(0xFF103847), Color(0xFF0BA99C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox, size: 24, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gelen toplam $proposalCount iş teklifiniz bulunuyor.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}