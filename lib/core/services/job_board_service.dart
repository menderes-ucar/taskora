import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../features/coin/data/services/coin_service.dart';
import '../../features/notification/data/services/notification_helper.dart';
import '../../shared/models/coin_model.dart';
import '../../shared/models/job_application_model.dart';
import '../../shared/models/job_posting_model.dart';
import '../../shared/enums/job_board_enums.dart';

// ====================================
// Abstract Interface
// ====================================

abstract class IJobBoardService {
  /// Freelancer bir iş ilanına başvurur
  /// UYARI: Bu fonksiyonda coin düşmesi INSERT'ten SONRA yapılır!
  /// UNIQUE constraint hatası (23505) yakalanıp özel mesaj verilir.
  Future<JobApplication> applyToJobPosting({
    required String jobPostingId,
    required String freelancerId,
    required String coverLetter,
    required double coinCost,
  });

  /// İş ilanı oluştur (henüz pending durumda)
  Future<JobPosting> createJobPosting({
    required String employerId,
    required String title,
    required String category,
    required WorkType workType,
    required ContractType contractType,
    required String description,
    String? salaryInfo,
    String? location,
  });

  /// Tek iş ilanını getir
  Future<JobPosting> getJobPosting(String jobPostingId);

  /// Onaylı iş ilanlarını listele (pagination)
  Future<List<JobPosting>> getApprovedJobPostings({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
  });

  /// İşveren'in kendi ilanlarını getir (tüm durumlar)
  Future<List<JobPosting>> getEmployerJobPostings(
      String employerId, {
        int page = 1,
        int limit = 20,
      });

  /// İlan detayını ve ilgili başvuruları getir
  Future<Map<String, dynamic>> getJobPostingWithApplications(
      String jobPostingId, {
        int page = 1,
        int limit = 10,
      });

  /// Freelancer'ın tüm başvurularını getir
  Future<List<JobApplication>> getFreelancerApplications(
      String freelancerId, {
        int page = 1,
        int limit = 20,
      });

  /// Belirli bir iş ilanına gelen başvuruları getir
  Future<List<JobApplication>> getJobApplications(
      String jobPostingId, {
        int page = 1,
        int limit = 20,
        ApplicationStatus? status,
      });

  /// Admin: İlanı onaylar (pending → approved)
  /// Bu işlem başarılı olursa işverene bildirim gönderilir
  Future<void> approveJobPosting(String jobPostingId);

  /// Admin: İlanı reddeder (pending → rejected)
  Future<void> rejectJobPosting({
    required String jobPostingId,
    String? reason,
  });

  /// İşveren: İlanını kapatır (iş tamamlandı)
  Future<void> closeJobPosting(String jobPostingId);

  /// İşveren: İlanını siler (sadece pending durumunda)
  Future<void> deleteJobPosting(String jobPostingId);

  /// İşveren: Başvuru durumunu güncelle (reviewed/accepted/rejected)
  /// Freelancer'a bildirim gönderilir
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
  });

  /// Freelancer: Kendi başvurusunu iptal eder (sadece pending durumunda)
  /// NOT: Ödediği coin geri VERILMEZ!
  Future<void> withdrawApplication(String applicationId, String freelancerId);

  /// Freelancer: Belirli bir iş ilanına zaten başvurup başvurmadığını kontrol et
  Future<bool> hasAppliedToJob({
    required String freelancerId,
    required String jobPostingId,
  });
}

// ====================================
// Concrete Implementation (Supabase)
// ====================================

class SupabaseJobBoardService implements IJobBoardService {
  final SupabaseClient _supabase;
  final CoinService _coinService;

  SupabaseJobBoardService(
      this._supabase, [
        CoinService? coinService,
      ]) : _coinService = coinService ?? CoinService(_supabase);

  static const String _jobPostingsTable = 'job_postings';
  static const String _jobApplicationsTable = 'job_applications';
  static const String _notificationsTable = 'notifications';

  // ====================================
  // BAŞVURU YAPMA - EN ÖNEMLİ KURAL!
  // ====================================

  @override
  Future<JobApplication> applyToJobPosting({
    required String jobPostingId,
    required String freelancerId,
    required String coverLetter,
    required double coinCost,
  }) async {
    try {
      // ⚠️ ADIM 1: Önce başvuruyu veritabanına ekle
      final applicationData = {
        'job_posting_id': jobPostingId,
        'freelancer_id': freelancerId,
        'cover_letter': coverLetter,
        'status': ApplicationStatus.pending.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_jobApplicationsTable)
          .insert(applicationData)
          .select()
          .single();

      final jobApplication = JobApplication.fromMap(response);

      // ✅ ADIM 2: INSERT başarılı olduktan SONRA coin düş
      try {
        await _coinService.deductCoin(
          freelancerId,                              // Positional 1
          coinCost.toInt(),                          // Positional 2
          CoinTransactionType.jobApplication,        // Positional 3 (YENİ!)
          relatedId: jobPostingId,                   // Named
          description: 'İş ilanına başvuru',         // Named
        );
      } catch (e) {
        // Coin düşüşü başarısız olsa bile başvuru zaten oluştu
        throw Exception('Başvuru oluşturuldu ancak coin düşümünde hata: $e');
      }

      // ✅ ADIM 3: İşverene bildirim gönder
      await _notifyEmployerNewApplication(jobPostingId, freelancerId);

      return jobApplication;
    } on PostgrestException catch (e) {
      // 🚨 UNIQUE constraint hatası: Kullanıcı zaten başvurmuş
      if (e.code == '23505') {
        throw Exception('Bu ilana zaten başvurdunuz!');
      }
      throw Exception('Başvuru yapılırken hata oluştu: ${e.message}');
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  // ====================================
  // İLAN OLUŞTURMA
  // ====================================

  @override
  Future<JobPosting> createJobPosting({
    required String employerId,
    required String title,
    required String category,
    required WorkType workType,
    required ContractType contractType,
    required String description,
    String? salaryInfo,
    String? location,
  }) async {
    try {
      final postingData = {
        'employer_id': employerId,
        'title': title,
        'category': category,
        'work_type': workType.name,
        'contract_type': contractType.name,
        'salary_info': salaryInfo,
        'location': location,
        'description': description,
        'status': PostingStatus.pending.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_jobPostingsTable)
          .insert(postingData)
          .select()
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('İş ilanı oluşturulurken hata oluştu: $e');
    }
  }

  // ====================================
  // İLAN GETIRME
  // ====================================

  @override
  Future<JobPosting> getJobPosting(String jobPostingId) async {
    try {
      final response = await _supabase
          .from(_jobPostingsTable)
          .select()
          .eq('id', jobPostingId)
          .single();

      return JobPosting.fromMap(response);
    } catch (e) {
      throw Exception('İş ilanı çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<JobPosting>> getApprovedJobPostings({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
  }) async {
    try {
      final offset = (page - 1) * limit;

      var query = _supabase
          .from(_jobPostingsTable)
          .select()
          .eq('status', PostingStatus.approved.name);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%${searchQuery.trim()}%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((job) => JobPosting.fromMap(job as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('İş ilanları çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<JobPosting>> getEmployerJobPostings(
      String employerId, {
        int page = 1,
        int limit = 20,
      }) async {
    try {
      final offset = (page - 1) * limit;

      final response = await _supabase
          .from(_jobPostingsTable)
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((job) => JobPosting.fromMap(job as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('İşverenin ilanları çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getJobPostingWithApplications(
      String jobPostingId, {
        int page = 1,
        int limit = 10,
      }) async {
    try {
      // İlanı getir
      final jobPosting = await getJobPosting(jobPostingId);

      // Başvuruları getir
      final applications = await getJobApplications(jobPostingId,
          page: page, limit: limit);

      return {
        'posting': jobPosting,
        'applications': applications,
      };
    } catch (e) {
      throw Exception('İlan ve başvurular çekilirken hata oluştu: $e');
    }
  }

  // ====================================
  // BAŞVURU GETIRME
  // ====================================

  @override
  Future<List<JobApplication>> getFreelancerApplications(
      String freelancerId, {
        int page = 1,
        int limit = 20,
      }) async {
    try {
      final offset = (page - 1) * limit;

      final response = await _supabase
          .from(_jobApplicationsTable)
          .select()
          .eq('freelancer_id', freelancerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((app) => JobApplication.fromMap(app as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Başvurularınız çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<List<JobApplication>> getJobApplications(
      String jobPostingId, {
        int page = 1,
        int limit = 20,
        ApplicationStatus? status,
      }) async {
    try {
      final offset = (page - 1) * limit;

      var query = _supabase
          .from(_jobApplicationsTable)
          .select()
          .eq('job_posting_id', jobPostingId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((app) => JobApplication.fromMap(app as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('İlan başvuruları çekilirken hata oluştu: $e');
    }
  }

  @override
  Future<bool> hasAppliedToJob({
    required String freelancerId,
    required String jobPostingId,
  }) async {
    try {
      final response = await _supabase
          .from(_jobApplicationsTable)
          .select()
          .eq('freelancer_id', freelancerId)
          .eq('job_posting_id', jobPostingId);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Başvuru durumu kontrol edilirken hata oluştu: $e');
    }
  }

  // ====================================
  // ADMIN: İLAN ONAY/RED
  // ====================================

  @override
  Future<void> approveJobPosting(String jobPostingId) async {
    try {
      // 1. İlanı onaylandı olarak işaretle
      await _supabase
          .from(_jobPostingsTable)
          .update({'status': PostingStatus.approved.name})
          .eq('id', jobPostingId);

      // 2. İşverene bildirim gönder
      await _notifyEmployerJobApproved(jobPostingId);
    } catch (e) {
      throw Exception('İlan onaylanırken hata oluştu: $e');
    }
  }

  @override
  Future<void> rejectJobPosting({
    required String jobPostingId,
    String? reason,
  }) async {
    try {
      // 1. İlanı reddedildi olarak işaretle
      await _supabase
          .from(_jobPostingsTable)
          .update({'status': PostingStatus.rejected.name})
          .eq('id', jobPostingId);

      // 2. İşverene bildirim gönder
      await _notifyEmployerJobRejected(jobPostingId, reason);
    } catch (e) {
      throw Exception('İlan reddedilirken hata oluştu: $e');
    }
  }

  // ====================================
  // İŞVEREN: İLAN KAPAMA/SİLME
  // ====================================

  @override
  Future<void> closeJobPosting(String jobPostingId) async {
    try {
      await _supabase
          .from(_jobPostingsTable)
          .update({'status': PostingStatus.closed.name})
          .eq('id', jobPostingId);
    } catch (e) {
      throw Exception('İlan kapatılırken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteJobPosting(String jobPostingId) async {
    try {
      // Sadece pending durumundaki ilanlar silinebilir
      final posting = await getJobPosting(jobPostingId);

      if (posting.status != PostingStatus.pending) {
        throw Exception('Sadece onay bekleyen ilanlar silinebilir');
      }

      await _supabase
          .from(_jobPostingsTable)
          .delete()
          .eq('id', jobPostingId);
    } catch (e) {
      throw Exception('İlan silinirken hata oluştu: $e');
    }
  }

  // ====================================
  // BAŞVURU DURUMU GÜNCELLEME
  // ====================================

  @override
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
  }) async {
    try {
      // Başvuruyu getir (freelancer_id'ye ihtiyacımız var)
      final application = await _getApplicationById(applicationId);

      // Status'ü güncelle
      await _supabase
          .from(_jobApplicationsTable)
          .update({'status': newStatus.name})
          .eq('id', applicationId);

      // Freelancer'a bildirim gönder
      await _notifyFreelancerApplicationStatus(
        freelancerId: application.freelancerId,
        applicationId: applicationId,
        newStatus: newStatus,
      );
    } catch (e) {
      throw Exception('Başvuru durumu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> withdrawApplication(
      String applicationId, String freelancerId) async {
    try {
      // Başvuruyu getir
      final application = await _getApplicationById(applicationId);

      // Freelancer kendi başvurusunu mu siliyor kontrol et
      if (application.freelancerId != freelancerId) {
        throw Exception('Bu başvuruyu iptal etme yetkiniz yok');
      }

      // Sadece pending başvurular iptal edilebilir
      if (application.status != ApplicationStatus.pending) {
        throw Exception('Sadece bekleyen başvurular iptal edilebilir');
      }

      // ⚠️ NOT: Coin GERİ VERİLMEZ! Kurallar gereği.

      // Başvuruyu sil
      await _supabase
          .from(_jobApplicationsTable)
          .delete()
          .eq('id', applicationId);
    } catch (e) {
      throw Exception('Başvuru iptal edilirken hata oluştu: $e');
    }
  }

  // ====================================
  // HELPER METHODS (Private)
  // ====================================

  /// Veritabanından başvuruyu getir
  Future<JobApplication> _getApplicationById(String applicationId) async {
    try {
      final response = await _supabase
          .from(_jobApplicationsTable)
          .select()
          .eq('id', applicationId)
          .single();

      return JobApplication.fromMap(response);
    } catch (e) {
      throw Exception('Başvuru çekilirken hata oluştu: $e');
    }
  }

  /// İşverene: Yeni başvuru bildirimini gönder
  Future<void> _notifyEmployerNewApplication(
      String jobPostingId, String freelancerId) async {
    try {
      // İlanın sahibini bul
      final jobPosting = await getJobPosting(jobPostingId);

      await NotificationHelper.sendNotification(
        targetUserId: jobPosting.employerId,
        title: 'Yeni Başvuru Geldi',
        body: 'İlanınıza yeni bir başvuru geldi',
        type: 'jobApplicationNew',
        relatedId: jobPostingId,
      );
    } catch (e) {
      // Bildirim başarısız olsa bile ana işlem başarılı sayılır
      print('⚠️ Bildirim gönderilemedi: $e');
    }
  }

  /// İşverene: İlan onaylandı bildirimi gönder
  Future<void> _notifyEmployerJobApproved(String jobPostingId) async {
    try {
      final jobPosting = await getJobPosting(jobPostingId);

      await NotificationHelper.sendNotification(
        targetUserId: jobPosting.employerId,
        title: 'İlan Onaylandı',
        body: '\"${jobPosting.title}\" başlıklı ilanınız onaylanmıştır',
        type: 'jobPostingApproved',
        relatedId: jobPostingId,
      );
    } catch (e) {
      print('⚠️ Bildirim gönderilemedi: $e');
    }
  }

  /// İşverene: İlan reddedildi bildirimi gönder
  Future<void> _notifyEmployerJobRejected(
      String jobPostingId, String? reason) async {
    try {
      final jobPosting = await getJobPosting(jobPostingId);

      final message =
          'İlanınız reddedilmiştir. Sebep: ${reason ?? "Belirtilmedi"}';

      await NotificationHelper.sendNotification(
        targetUserId: jobPosting.employerId,
        title: 'İlan Reddedildi',
        body: message,
        type: 'jobPostingRejected',
        relatedId: jobPostingId,
      );
    } catch (e) {
      print('⚠️ Bildirim gönderilemedi: $e');
    }
  }

  /// Freelancer'a: Başvuru durumu değişti bildirimi gönder
  Future<void> _notifyFreelancerApplicationStatus({
    required String freelancerId,
    required String applicationId,
    required ApplicationStatus newStatus,
  }) async {
    try {
      String title, message;

      switch (newStatus) {
        case ApplicationStatus.reviewed:
          title = 'Başvurunuz İncelendi';
          message = 'Başvurunuz incelemeye alınmıştır';
          break;
        case ApplicationStatus.accepted:
          title = 'Tebrikler! ✨';
          message = 'Başvurunuz kabul edilmiştir';
          break;
        case ApplicationStatus.rejected:
          title = 'Başvuru Durumu';
          message = 'Maalesef başvurunuz bu kez kabul edilememiştir';
          break;
        default:
          title = 'Başvuru Güncellemesi';
          message = 'Başvurunuzda değişiklik var';
      }

      await NotificationHelper.sendNotification(
        targetUserId: freelancerId,
        title: title,
        body: message,
        type: 'applicationStatusUpdated',
        relatedId: applicationId,
      );
    } catch (e) {
      print('⚠️ Bildirim gönderilemedi: $e');
    }
  }
}