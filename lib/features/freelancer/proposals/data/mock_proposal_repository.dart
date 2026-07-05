import '../../../../shared/data/mock_data.dart';
import '../../../../shared/enums/proposal_status.dart';
import '../../../../shared/models/proposal_model.dart';
import 'proposal_repository.dart';

class MockProposalRepository implements ProposalRepository {
  final List<ProposalModel> _proposals =
  List<ProposalModel>.from(MockData.proposals);

  @override
  Future<List<ProposalModel>> getAllProposals() async {
    return List<ProposalModel>.from(_proposals);
  }

  @override
  Future<List<ProposalModel>> getByFreelancer(String freelancerId) async {
    return _proposals
        .where((proposal) => proposal.freelancerId == freelancerId)
        .toList();
  }

  @override
  Future<List<ProposalModel>> getByJob(String jobId) async {
    return _proposals.where((proposal) => proposal.jobId == jobId).toList();
  }

  @override
  Future<ProposalModel?> getById(String id) async {
    try {
      return _proposals.firstWhere((proposal) => proposal.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasFreelancerAlreadyProposed({
    required String jobId,
    required String freelancerId,
  }) async {
    return _proposals.any(
          (proposal) =>
      proposal.jobId == jobId && proposal.freelancerId == freelancerId,
    );
  }

  @override
  Future<void> addProposal(ProposalModel proposal) async {
    _proposals.insert(0, proposal);
  }

  @override
  Future<void> updateProposalStatus(
      String proposalId,
      ProposalStatus status,
      ) async {
    final index = _proposals.indexWhere((proposal) => proposal.id == proposalId);
    if (index == -1) return;

    _proposals[index] = _proposals[index].copyWith(status: status);
  }
}