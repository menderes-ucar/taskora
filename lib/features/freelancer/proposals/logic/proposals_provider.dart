import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/enums/app_notification_type.dart';
import '../../../../shared/enums/proposal_status.dart';
import '../../../../shared/models/proposal_model.dart';
import '../../notification/services/notification_helper.dart';
import '../data/proposal_repository_provider.dart';

class ProposalsNotifier extends AsyncNotifier<List<ProposalModel>> {
  @override
  Future<List<ProposalModel>> build() async {
    return _loadProposals();
  }

  Future<List<ProposalModel>> _loadProposals() async {
    final repository = ref.read(proposalRepositoryProvider);
    return repository.getAllProposals();
  }

  Future<void> refreshProposals() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => _loadProposals());
  }

  ProposalModel? getById(String id) {
    final proposals = state.valueOrNull ?? [];
    try {
      return proposals.firstWhere((proposal) => proposal.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ProposalModel> getByFreelancer(String freelancerId) {
    final proposals = state.valueOrNull ?? [];
    return proposals
        .where((proposal) => proposal.freelancerId == freelancerId)
        .toList();
  }

  List<ProposalModel> getByJob(String jobId) {
    final proposals = state.valueOrNull ?? [];
    return proposals.where((proposal) => proposal.jobId == jobId).toList();
  }

  Future<bool> hasFreelancerAlreadyProposed({
    required String jobId,
    required String freelancerId,
  }) async {
    final repository = ref.read(proposalRepositoryProvider);
    return repository.hasFreelancerAlreadyProposed(
      jobId: jobId,
      freelancerId: freelancerId,
    );
  }

  Future<void> addProposal(ProposalModel proposal) async {
    final repository = ref.read(proposalRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.addProposal(proposal);
      return _loadProposals();
    });
  }

  Future<void> updateProposalStatus(
      String proposalId,
      ProposalStatus status,
      ) async {
    final repository = ref.read(proposalRepositoryProvider);
    final proposal = getById(proposalId);

    state = await AsyncValue.guard(() async {
      await repository.updateProposalStatus(proposalId, status);
      return _loadProposals();
    });

    if (proposal == null) return;

    if (status == ProposalStatus.accepted) {
      NotificationHelper.send(
        ref: ref,
        userId: proposal.freelancerId,
        title: 'Teklif kabul edildi',
        body: 'Gönderdiğin teklif kabul edildi.',
        type: AppNotificationType.proposalAccepted,
        relatedId: proposal.id,
      );
    }

    if (status == ProposalStatus.rejected) {
      NotificationHelper.send(
        ref: ref,
        userId: proposal.freelancerId,
        title: 'Teklif reddedildi',
        body: 'Gönderdiğin teklif reddedildi.',
        type: AppNotificationType.proposalRejected,
        relatedId: proposal.id,
      );
    }
  }
}

final proposalsProvider =
AsyncNotifierProvider<ProposalsNotifier, List<ProposalModel>>(
  ProposalsNotifier.new,
);