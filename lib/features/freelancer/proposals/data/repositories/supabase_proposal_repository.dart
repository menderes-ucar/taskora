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
    final response = await _supabase.rpc(
      'submit_proposal_safely',
      params: {
        'p_job_id': proposal.jobId,
        'p_freelancer_id': proposal.freelancerId,
        'p_freelancer_name': proposal.freelancerName,
        'p_amount': proposal.amount,
        'p_delivery_days': proposal.deliveryDays,
        'p_cover_letter': proposal.coverLetter,
        'p_coin_cost': proposal.coinCost,
      },
    );

    if (response == null) {
      throw Exception('Teklif oluşturulamadı.');
    }
  }

  @override
  Future<void> selectProposalForJob({
    required String proposalId,
  }) async {
    try {
      await _supabase.rpc(
        'select_freelancer_for_job_atomic',
        params: {
          'p_proposal_id': proposalId,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Freelancer seçilemedi. Lütfen tekrar deneyin.');
    }
  }

  @override
  Future<void> updateProposalStatus(
      String proposalId,
      ProposalStatus status,
      ) async {
    if (status == ProposalStatus.withdrawn) {
      await _supabase.rpc(
        'withdraw_proposal_secure',
        params: {'p_proposal_id': proposalId},
      );
      return;
    }

    if (status != ProposalStatus.accepted &&
        status != ProposalStatus.rejected) {
      throw ArgumentError('Desteklenmeyen proposal status: ${status.name}');
    }

    await _supabase.rpc(
      'change_proposal_status_rpc',
      params: {
        'p_proposal_id': proposalId,
        'p_status': status.name,
      },
    );
  }
}