import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../../features/coin/data/services/coin_service.dart';
import '../../features/notification/data/services/notification_helper.dart';
import '../../shared/models/coin_model.dart';
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
      final proposalData = {
        'amount': proposal.amount,
        'cover_letter': proposal.coverLetter,
        'delivery_days': proposal.deliveryDays,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('proposals')
          .update(proposalData)
          .eq('id', proposalId)
          .select()
          .single();

      return ProposalModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> acceptProposal(String proposalId) async {
    try {
      final proposalResponse = await _supabase
          .from('proposals')
          .select('''
            *,
            job:job_id(title, employer_id)
          ''')
          .eq('id', proposalId)
          .single();

      final String jobId = proposalResponse['job_id'] as String;
      final String freelancerId = proposalResponse['freelancer_id'] as String;
      final String freelancerName = proposalResponse['freelancer_name'] as String? ?? 'Freelancer';
      final double amount = (proposalResponse['amount'] as num).toDouble();
      final int deliveryDays = proposalResponse['delivery_days'] as int;

      final String employerId = proposalResponse['job']?['employer_id'] ??
          _supabase.auth.currentUser?.id ?? '';
      final String jobTitle = proposalResponse['job']?['title'] ?? 'Kabul Edilen Proje';

      await _supabase
          .from('proposals')
          .update({
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
      })
          .eq('id', proposalId);

      await _supabase
          .from('jobs')
          .update({'status': 'inProgress'})
          .eq('id', jobId);

      await _supabase.from('contracts').insert({
        'job_id': jobId,
        'employer_id': employerId,
        'freelancer_id': freelancerId,
        'job_title': jobTitle,
        'freelancer_name': freelancerName,
        'agreed_amount': amount,
        'delivery_days': deliveryDays,
        'status': 'active',
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Teklif kabul edildi ve aktif projeler listesine yeni kontrat eklendi!');
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> rejectProposal(String proposalId) async {
    try {
      await _supabase
          .from('proposals')
          .update({
        'status': 'rejected',
        'rejected_at': DateTime.now().toIso8601String(),
      })
          .eq('id', proposalId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> withdrawProposal(String proposalId) async {
    try {
      await _supabase
          .from('proposals')
          .update({
        'status': 'withdrawn',
        'withdrawn_at': DateTime.now().toIso8601String(),
      })
          .eq('id', proposalId);
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
      final proposals = await _supabase
          .from('proposals')
          .select()
          .eq('job_id', jobId)
          .neq('freelancer_id', selectedFreelancerId);

      for (final proposal in proposals as List) {
        final proposalId = proposal['id'] as String;
        final freelancerId = proposal['freelancer_id'] as String;
        final coinCost = (proposal['coin_cost'] as num?)?.toInt() ?? 0;
        final coinRefunded = proposal['coin_refunded'] as bool? ?? false;

        if (coinRefunded || coinCost == 0) continue;

        final refundAmount = (coinCost * 0.5).toInt();

        await _coinService.refundCoin(
          freelancerId,
          refundAmount,
          'İş başka birine verildi',
          relatedId: proposalId,
        );

        await _supabase
            .from('proposals')
            .update({'coin_refunded': true})
            .eq('id', proposalId);
      }
    } catch (e) {
      print('❌ refundCoinsForRejectedProposals error: $e');
      rethrow;
    }
  }

  @override
  Future<void> refundCoinsForCancelledJob(String jobId) async {
    try {
      final proposals = await _supabase
          .from('proposals')
          .select()
          .eq('job_id', jobId)
          .eq('status', 'pending');

      for (final proposal in proposals as List) {
        final proposalId = proposal['id'] as String;
        final freelancerId = proposal['freelancer_id'] as String;
        final coinCost = (proposal['coin_cost'] as num?)?.toInt() ?? 0;
        final coinRefunded = proposal['coin_refunded'] as bool? ?? false;

        if (coinRefunded || coinCost == 0) continue;

        await _coinService.refundCoin(
          freelancerId,
          coinCost,
          'İş iptal edildi',
          relatedId: proposalId,
        );

        await _supabase
            .from('proposals')
            .update({'coin_refunded': true})
            .eq('id', proposalId);
      }
    } catch (e) {
      print('❌ refundCoinsForCancelledJob error: $e');
      rethrow;
    }
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