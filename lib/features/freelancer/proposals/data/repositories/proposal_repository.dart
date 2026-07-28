import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/proposal_model.dart';

abstract class ProposalRepository {
  Future<List<ProposalModel>> getAllProposals();

  Future<List<ProposalModel>> getByFreelancer(String freelancerId);

  Future<List<ProposalModel>> getByJob(String jobId);

  Future<ProposalModel?> getById(String id);

  Future<bool> hasFreelancerAlreadyProposed({
    required String jobId,
    required String freelancerId,
  });

  Future<void> addProposal(ProposalModel proposal);

  Future<void> updateProposalStatus(String proposalId, ProposalStatus status);
}