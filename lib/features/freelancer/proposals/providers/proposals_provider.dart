import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/enums/app_notification_type.dart';
import '../../../../shared/enums/proposal_status.dart';
import '../../../../shared/models/proposal_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';

import '../../../notification/data/services/notification_helper.dart';
import '../data/proposal_repository_provider.dart';

class ProposalsNotifier extends AsyncNotifier<List<ProposalModel>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<List<ProposalModel>> build() async {
    _initRealtimeStream();
    return _loadProposals();
  }

  void _initRealtimeStream() {
    _subscription?.cancel();
    try {
      final client = Supabase.instance.client;

      _subscription = client
          .from('proposals')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
            (data) {
          final proposals =
          data.map((map) => ProposalModel.fromMap(map)).toList();
          state = AsyncValue.data(proposals);
        },
        onError: (error, stack) async {
          debugPrint('⚠️ [Realtime Proposals Hata]: $error');
          if (error.toString().contains('invalidJWTToken') ||
              error.toString().contains('expired')) {
            try {
              await client.auth.refreshSession();
              _initRealtimeStream();
            } catch (e) {
              _loadProposals().then((list) => state = AsyncValue.data(list));
            }
          } else {
            state = AsyncValue.error(error, stack);
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Realtime Subscription Error]: $e');
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });
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
    final authState = ref.read(authProvider);

    final alreadyProposed = await hasFreelancerAlreadyProposed(
      jobId: proposal.jobId,
      freelancerId: proposal.freelancerId,
    );

    if (alreadyProposed) {
      throw Exception('Bu ilana zaten bir teklif verdiniz.');
    }

    if (authState.user != null) {
      final currentProposalsCount = getByFreelancer(authState.user!.id).length;
      if (currentProposalsCount >= authState.user!.proposalLimit) {
        throw Exception('limit_error_desc');
      }
    }

    await repository.addProposal(proposal);
  }

  Future<void> selectProposalForJob(String proposalId) async {
    final repository = ref.read(proposalRepositoryProvider);

    await repository.selectProposalForJob(proposalId: proposalId);
    await refreshProposals();

    final selectedProposal = getById(proposalId);
    if (selectedProposal != null) {
      await NotificationHelper.send(
        targetUserId: selectedProposal.freelancerId,
        title: 'Teklifin kabul edildi!',
        body: 'İşveren teklifini onayladı. Proje artık devam ediyor.',
        type: AppNotificationType.proposalAccepted.name,
        relatedId: selectedProposal.id,
      );
    }
  }

  Future<void> updateProposalStatus(
      String proposalId,
      ProposalStatus status,
      ) async {
    final repository = ref.read(proposalRepositoryProvider);

    await repository.updateProposalStatus(proposalId, status);

    await refreshProposals();

    if (status == ProposalStatus.accepted) {
      final proposal = getById(proposalId);
      if (proposal != null) {
        await NotificationHelper.send(
          targetUserId: proposal.freelancerId,
          title: 'Teklifin kabul edildi!',
          body: 'İşveren teklifini onayladı. Proje artık devam ediyor.',
          type: AppNotificationType.proposalAccepted.name,
          relatedId: proposal.id,
        );
      }
    }
  }
}

final proposalsProvider =
AsyncNotifierProvider<ProposalsNotifier, List<ProposalModel>>(
  ProposalsNotifier.new,
);