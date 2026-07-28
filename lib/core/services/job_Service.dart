import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/config/coin_constants.dart';
import '../../core/services/proposal_service.dart';
import '../../features/coin/data/services/coin_service.dart';

import '../../shared/models/job_model.dart';

abstract class IJobService {
  Future<List<JobModel>> getJobs({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
    String? status,
  });

  Future<JobModel> getJobDetail(String jobId);
  Future<JobModel> createJob(JobModel job);
  Future<JobModel> updateJob(String jobId, JobModel job);
  Future<void> deleteJob(String jobId);
  Future<List<JobModel>> getMyJobs(String employerId);
  Future<void> closeJob(String jobId);
  Future<void> cancelJob(String jobId);
  Future<void> selectFreelancer(String jobId, String selectedFreelancerId);
}

class SupabaseJobService implements IJobService {
  final SupabaseClient _supabase;
  final CoinService _coinService;
  final SupabaseProposalService _proposalService;

  SupabaseJobService(
      this._supabase, [
        CoinService? coinService,
        SupabaseProposalService? proposalService,
      ])  : _coinService = coinService ?? CoinService(_supabase),
        _proposalService = proposalService ?? SupabaseProposalService(_supabase);

  static const String _table = 'jobs';

  @override
  Future<List<JobModel>> getJobs({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
    String? status,
  }) async {
    try {
      final int offset = (page - 1) * limit;

      var query = _supabase
          .from(_table)
          .select()
          .eq('status', status ?? 'open');

      if (category != null && category.trim().isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('title', '%${searchQuery.trim()}%');
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((job) => JobModel.fromMap(job as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('İlanlar çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<JobModel> getJobDetail(String jobId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', jobId)
          .single();

      return JobModel.fromMap(response);
    } catch (e) {
      throw Exception('İlan detayı çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<JobModel> createJob(JobModel job) async {
    try {
      // 1. Coin Bakiye Kontrolü ve Düşümü
      await _coinService.checkAndDeductCoins(
        userId: job.employerId,
        requiredCoins: CoinConstants.createJobCost,
        actionDescription: '${job.title} başlıklı ilan oluşturuldu.',
      );

      // 2. İlan Verisinin Veritabanına Yazılması
      final jobData = job.toMap();
      jobData['status'] = job.status.name;
      jobData['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_table)
          .insert(jobData)
          .select()
          .single();

      return JobModel.fromMap(response);
    } catch (e) {
      throw Exception('İlan oluşturulurken hata oluştu: $e');
    }
  }

  @override
  Future<JobModel> updateJob(String jobId, JobModel job) async {
    try {
      final jobData = job.toMap();
      jobData['status'] = job.status.name;

      final response = await _supabase
          .from(_table)
          .update(jobData)
          .eq('id', jobId)
          .select()
          .single();

      return JobModel.fromMap(response);
    } catch (e) {
      throw Exception('İlan güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteJob(String jobId) async {
    try {
      await _supabase.from(_table).delete().eq('id', jobId);
    } catch (e) {
      throw Exception('İlan silinirken hata oluştu: $e');
    }
  }

  @override
  Future<List<JobModel>> getMyJobs(String employerId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((job) => JobModel.fromMap(job as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('İlanlarım çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<void> closeJob(String jobId) async {
    try {
      await _supabase
          .from(_table)
          .update({'status': 'closed'})
          .eq('id', jobId);
    } catch (e) {
      throw Exception('İlan kapatılırken hata oluştu: $e');
    }
  }

  // 🚀 İş İptal Edildiğinde / Silindiğinde
  @override
  Future<void> cancelJob(String jobId) async {
    try {
      // İş silinince tüm teklif verenlere %100 coin iadesi yap
      await _proposalService.refundCoinsForCancelledJob(jobId);

      // İş durumunu güncelle
      await _supabase.from('jobs').update({'status': 'cancelled'}).eq('id', jobId);
    } catch (e) {
      print('❌ cancelJob error: $e');
      rethrow;
    }
  }

  // 🚀 Freelancer Seçildiğinde
  @override
  Future<void> selectFreelancer(String jobId, String selectedFreelancerId) async {
    try {
      // Seçilmeyen, reddedilen tekliflere %50 coin iadesi yap
      await _proposalService.refundCoinsForRejectedProposals(
        jobId: jobId,
        selectedFreelancerId: selectedFreelancerId,
      );

    } catch (e) {
      print('❌ selectFreelancer error: $e');
      rethrow;
    }
  }
}