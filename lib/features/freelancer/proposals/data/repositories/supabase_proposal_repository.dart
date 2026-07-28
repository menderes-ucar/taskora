import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/proposal_model.dart';
import 'proposal_repository.dart';

class SupabaseProposalRepository implements ProposalRepository {
  final SupabaseClient _supabase;

  SupabaseProposalRepository(this._supabase);

  static const String _table = 'proposals';

  @override
  Future<List<ProposalModel>> getAllProposals() async {
    final response = await _supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ProposalModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<bool> hasUserApplied({
    required String jobId,
    required String freelancerId,
  }) async {
    final response = await _supabase
        .from(_table)
        .select('id')
        .eq('job_id', jobId)
        .eq('freelancer_id', freelancerId)
        .maybeSingle();

    return response != null;
  }

  @override
  Future<List<ProposalModel>> getByFreelancer(String freelancerId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('freelancer_id', freelancerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ProposalModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<ProposalModel>> getByJob(String jobId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('job_id', jobId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ProposalModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<ProposalModel?> getById(String id) async {
    final response =
    await _supabase.from(_table).select().eq('id', id).maybeSingle();

    if (response == null) return null;

    return ProposalModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<bool> hasFreelancerAlreadyProposed({
    required String jobId,
    required String freelancerId,
  }) async {
    final response = await _supabase
        .from(_table)
        .select('id')
        .eq('job_id', jobId)
        .eq('freelancer_id', freelancerId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  @override
  Future<void> addProposal(ProposalModel proposal) async {
    await _supabase.from(_table).insert(proposal.toInsertMap());
  }

  @override
  Future<void> updateProposalStatus(
      String proposalId,
      ProposalStatus status,
      ) async {
    await _supabase.from(_table).update({
      'status': status.name,
    }).eq('id', proposalId);
  }
}