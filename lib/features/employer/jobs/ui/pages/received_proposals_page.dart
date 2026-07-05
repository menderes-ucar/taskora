import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/enums/contract_status.dart';
import '../../../../../shared/enums/job_status.dart';
import '../../../../../shared/enums/payment_status.dart';
import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/contract_model.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../../shared/models/proposal_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../contracts/logic/contracts_provider.dart';
import '../../../../freelancer/jobs/ui/logic/jobs_provider.dart';
import '../../../../freelancer/proposals/logic/proposals_provider.dart';
import '../../../freelancers/ui/pages/freelancer_detail_page.dart';

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
              appBar: AppBar(
                title: const Text('Gelen Teklifler'),
              ),
              body: receivedProposals.isEmpty
                  ? const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Henüz gelen teklif yok',
                subtitle: 'İlanlarına teklif geldikçe burada görünecek.',
              )
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _TopBanner(
                    proposalCount: receivedProposals.length,
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(receivedProposals.length, (index) {
                    final proposal = receivedProposals[index];
                    final relatedJob = myJobs.firstWhere(
                          (job) => job.id == proposal.jobId,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReceivedProposalCard(
                        proposal: proposal,
                        relatedJob: relatedJob,
                      ),
                    );
                  }),
                ],
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  proposal.freelancerName.isNotEmpty
                      ? proposal.freelancerName.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      relatedJob.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip(
                label: _statusText(),
                color: statusColor.withValues(alpha: 0.12),
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(label: relatedJob.category),
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
              maxLines: 5,
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
                title: 'Teklif',
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
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Profili Gör',
            icon: Icons.person_outline_rounded,
            onPressed: () {
              print('FREELANCER ID: ${proposal.freelancerId}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FreelancerDetailPage(
                    freelancerId: proposal.freelancerId,
                  ),
                ),
              );
            },
          ),
          if (proposal.status == ProposalStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(proposalsProvider.notifier)
                          .updateProposalStatus(
                        proposal.id,
                        ProposalStatus.rejected,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Teklif reddedildi'),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Reddet',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final proposalsNotifier =
                        ref.read(proposalsProvider.notifier);
                        final contractsNotifier =
                        ref.read(contractsProvider.notifier);
                        final jobsNotifier = ref.read(jobsProvider.notifier);

                        final hasContract =
                        contractsNotifier.hasContractForJob(proposal.jobId);

                        if (hasContract) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bu iş için zaten sözleşme oluşturulmuş',
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        final job = jobsNotifier.getById(proposal.jobId);

                        if (job == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('İş bilgisi bulunamadı'),
                              ),
                            );
                          }
                          return;
                        }

                        await proposalsNotifier.updateProposalStatus(
                          proposal.id,
                          ProposalStatus.accepted,
                        );

                        final contract = ContractModel(
                          id: const Uuid().v4(),
                          jobId: job.id,
                          jobTitle: job.title,
                          employerId: job.employerId,
                          freelancerId: proposal.freelancerId,
                          freelancerName: proposal.freelancerName,
                          agreedAmount: proposal.amount,
                          deliveryDays: proposal.deliveryDays,
                          status: ContractStatus.active,
                          paymentStatus: PaymentStatus.pending,
                          createdAt: DateTime.now(),
                        );

                        await contractsNotifier.addContract(contract);

                        await jobsNotifier.updateJobStatus(
                          job.id,
                          JobStatus.inProgress,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Teklif kabul edildi ve sözleşme oluşturuldu',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    child: const Text('Kabul Et'),
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

  const _TopBanner({
    required this.proposalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox, size: 28),
          const SizedBox(width: 12),
          Text(
            '$proposalCount teklif aldın',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
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
        Icon(
          icon,
          size: 18,
          color: AppColors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.grey,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}