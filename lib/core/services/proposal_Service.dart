import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/coin/data/services/coin_service.dart';
import '../../features/notification/data/services/notification_helper.dart';
import '../../shared/models/proposal_model.dart';
import '../error/app_exception.dart';

// 1. ARAYÜZ (INTERFACE) - İÇİNDE GÖVDE/KOD OLMAZ
abstract class IProposalService {
  Future<List<ProposalModel>> getProposalsForJob(String jobId);
  Future<List<ProposalModel>> getMyProposals(String freelancerId);
  Future<ProposalModel> getProposal(String proposalId);

  Future<String> createProposalWithCoinDeduction({
    required ProposalModel proposal,
    required int coinCost,
    required String jobCategoryId,

  });

  Future<ProposalModel> updateProposal(String proposalId, ProposalModel proposal);
  Future<void> acceptProposal(String proposalId);
  Future<void> rejectProposal(String proposalId);
  Future<void> withdrawProposal(String proposalId);

  Future<void> refundCoinsForRejectedProposals({
    required String jobId,
    required String selectedFreelancerId,
  });
  Future<void> refundCoinsForCancelledJob(String jobId);
}

// 2. GERÇEK UYGULAMA (IMPLEMENTATION) - KODLAR VE METOT GÖVDELERİ BURADADIR
class SupabaseProposalService implements IProposalService {
  final SupabaseClient _supabase;
  late final SupabaseCoinService _coinService;

  SupabaseProposalService([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client {
    _coinService = SupabaseCoinService(_supabase);
  }

  @override
  Future<List<ProposalModel>> getProposalsForJob(String jobId) async {
    try {
      final response = await _supabase
          .from('proposals')
          .select('''
            *,
            freelancer:freelancer_id(*)
          ''')
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      return List<ProposalModel>.from(
        (response as List).map(
              (proposal) => ProposalModel.fromJson(proposal as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<ProposalModel>> getMyProposals(String freelancerId) async {
    try {
      final response = await _supabase
          .from('proposals')
          .select('''
            *,
            job:job_id(*)
          ''')
          .eq('freelancer_id', freelancerId)
          .order('created_at', ascending: false);

      return List<ProposalModel>.from(
        (response as List).map(
              (proposal) => ProposalModel.fromJson(proposal as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<ProposalModel> getProposal(String proposalId) async {
    try {
      final response = await _supabase
          .from('proposals')
          .select('''
            *,
            freelancer:freelancer_id(*),
            job:job_id(*)
          ''')
          .eq('id', proposalId)
          .single();

      return ProposalModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<String> createProposalWithCoinDeduction({
    required ProposalModel proposal,
    required int coinCost,
    required String jobCategoryId,
  }) async {
    try {
      print("RPC ÇAĞRILMADAN ÖNCE");
      final balance1 = await _coinService.getUserCoinBalance(proposal.freelancerId);
      print("Coin önce: $balance1");
      final response = await _supabase.rpc('submit_proposal_safely', params: {
        'p_job_id': proposal.jobId,
        'p_freelancer_id': proposal.freelancerId,
        'p_freelancer_name': proposal.freelancerName,
        'p_amount': proposal.amount,
        'p_delivery_days': proposal.deliveryDays,
        'p_cover_letter': proposal.coverLetter,
        'p_coin_cost': coinCost,
      });
      final balance2 = await _coinService.getUserCoinBalance(proposal.freelancerId);
      print("Coin sonra: $balance2");
      final String proposalId = response.toString();
      print("RPC sonucu = $proposalId");
      // İlan sahibine bildirim gönder
      try {
        final jobResponse = await _supabase
            .from('jobs')
            .select('employer_id, title')
            .eq('id', proposal.jobId)
            .single();

        final String? employerId = jobResponse['employer_id']?.toString();
        final String jobTitle = jobResponse['title']?.toString() ?? 'İlanınız';

        if (employerId != null && employerId.isNotEmpty) {
          await NotificationHelper.sendNotification(
            targetUserId: employerId,
            title: 'Yeni Teklif Alındı! 📩',
            body: '"$jobTitle" ilanınıza yeni bir teklif yapıldı.',
            type: 'newProposal',
            relatedId: proposalId,
          );
        }
      } catch (notifErr) {
        print('⚠️ Bildirim gönderilemedi fakat teklif eklendi: $notifErr');
      }

      return proposalId;
    } on PostgrestException catch (pgErr) {
      throw pgErr.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProposalModel> updateProposal(
      String proposalId,
      ProposalModel proposal,
      ) async {
    try {
      final response = await _supabase.rpc(
        'update_proposal_secure',
        params: {
          'p_proposal_id': proposalId,
          'p_amount': proposal.amount,
          'p_delivery_days': proposal.deliveryDays,
          'p_cover_letter': proposal.coverLetter,
        },
      );

      return ProposalModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> acceptProposal(String proposalId) async {
    try {
      await _supabase.rpc(
        'change_proposal_status_rpc',
        params: {
          'p_proposal_id': proposalId,
          'p_status': 'accepted',
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> rejectProposal(String proposalId) async {
    try {
      await _supabase.rpc(
        'change_proposal_status_rpc',
        params: {
          'p_proposal_id': proposalId,
          'p_status': 'rejected',
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> withdrawProposal(String proposalId) async {
    try {
      await _supabase.rpc(
        'withdraw_proposal_secure',
        params: {'p_proposal_id': proposalId},
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> refundCoinsForRejectedProposals({
    required String jobId,
    required String selectedFreelancerId,
  }) async {
    try {
      await _supabase.rpc('refund_job_proposals_atomic', params: {
        'p_job_id': jobId,
        'p_selected_freelancer_id': selectedFreelancerId,
        'p_full_refund': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> refundCoinsForCancelledJob(String jobId) async {
    await _supabase.rpc('refund_job_proposals_atomic', params: {
      'p_job_id': jobId,
      'p_selected_freelancer_id': null,
      'p_full_refund': true,
    });
  }

}

// Global Standalone Yardımcı Fonksiyon (Sınıf Dışındaki Eski Çağrılar İçin)
Future<String> createProposalWithCoinDeduction({

  required SupabaseClient supabase,
  required ProposalModel proposal,
  required int coinCost,
  required String jobCategoryId,

}) {
  return SupabaseProposalService(supabase).createProposalWithCoinDeduction(
    proposal: proposal,
    coinCost: coinCost,
    jobCategoryId: jobCategoryId,

  );
}