import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/job_board_service.dart';
import '../../../../shared/enums/job_board_enums.dart';
import '../../../../shared/models/job_posting_model.dart';


// ====================================
// Job Postings Notifier
// ====================================

class JobPostingsNotifier extends AsyncNotifier<List<JobPosting>> {
  late IJobBoardService _jobBoardService;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<List<JobPosting>> build() async {
    _jobBoardService = ref.watch(jobBoardServiceProvider);

    // Cleanup subscription when provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // İlk yükleme (onaylı ilanlar)
    final initialData =
    await _jobBoardService.getApprovedJobPostings(page: 1, limit: 100);

    // Realtime dinlemesini başlat
    _initRealtimeStream();

    return initialData;
  }

  /// Supabase'den canlı dinleme başlat
  /// Admin onay/red yaptığında veya yeni ilan açıldığında otomatik güncelleme
  void _initRealtimeStream() {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('job_postings')
        .stream(primaryKey: ['id'])
        .eq('status', PostingStatus.approved.name) // Sadece onaylı ilanlar
        .order('created_at', ascending: false)
        .listen(
          (data) {
            final postings = data
                .map((map) => JobPosting.fromMap(map))
                .toList();
        state = AsyncValue.data(postings);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  // ====================================
  // CRUD Operasyonları
  // ====================================

  /// Yeni iş ilanı oluştur
  Future<JobPosting> createPosting({
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
      state = const AsyncValue.loading();

      final newPosting = await _jobBoardService.createJobPosting(
        employerId: employerId,
        title: title,
        category: category,
        workType: workType,
        contractType: contractType,
        description: description,
        salaryInfo: salaryInfo,
        location: location,
      );

      // Realtime stream otomatik güncelleyecek
      return newPosting;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Admin: İlanı onaylar
  /// İşverene bildirim gönderilir + Realtime otomatik güncelleme
  Future<void> approvePosting(String jobPostingId) async {
    try {
      state = const AsyncValue.loading();
      await _jobBoardService.approveJobPosting(jobPostingId);
      // Realtime stream otomatik güncelleyecek
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Admin: İlanı reddeder
  /// İşverene bildirim gönderilir
  Future<void> rejectPosting({
    required String jobPostingId,
    String? reason,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _jobBoardService.rejectJobPosting(
        jobPostingId: jobPostingId,
        reason: reason,
      );
      // Reddedilen ilanlar listeden silinecek (sadece approved gösterilir)
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// İşveren: İlanını kapatır (iş tamamlandı)
  Future<void> closePosting(String jobPostingId) async {
    try {
      state = const AsyncValue.loading();
      await _jobBoardService.closeJobPosting(jobPostingId);
      // Realtime stream otomatik güncelleyecek
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// İşveren: İlanını siler (sadece pending)
  Future<void> deletePosting(String jobPostingId) async {
    try {
      state = const AsyncValue.loading();
      await _jobBoardService.deleteJobPosting(jobPostingId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // ====================================
  // Helper Metodları
  // ====================================

  /// ID'ye göre ilanı getir (mevcut verilerden)
  JobPosting? getPostingById(String id) {
    final postings = state.valueOrNull ?? [];
    try {
      return postings.firstWhere((posting) => posting.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tüm ilanları manuel olarak yenile
  Future<void> refreshPostings() async {
    try {
      state = const AsyncValue.loading();
      final refreshedData = await _jobBoardService.getApprovedJobPostings(
        page: 1,
        limit: 100,
      );
      state = AsyncValue.data(refreshedData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// ====================================
// Providers
// ====================================

/// Ana provider: Tüm onaylı iş ilanları (Realtime)
final jobPostingsProvider =
AsyncNotifierProvider<JobPostingsNotifier, List<JobPosting>>(
  JobPostingsNotifier.new,
);

/// Kategori bazlı filtrelenmiş ilanlar
final jobPostingsByCategoryProvider =
Provider.family<List<JobPosting>, String>((ref, category) {
  final postingsAsync = ref.watch(jobPostingsProvider);
  return postingsAsync.maybeWhen(
    data: (postings) =>
        postings.where((p) => p.category == category).toList(),
    orElse: () => [],
  );
});

/// Arama sorgusu bazlı ilanlar
final jobPostingsBySearchProvider =
Provider.family<List<JobPosting>, String>((ref, query) {
  final postingsAsync = ref.watch(jobPostingsProvider);
  return postingsAsync.maybeWhen(
    data: (postings) => postings
        .where((p) =>
    p.title.toLowerCase().contains(query.toLowerCase()) ||
        p.description.toLowerCase().contains(query.toLowerCase()))
        .toList(),
    orElse: () => [],
  );
});

/// İşveren'in kendi ilanları (tüm durumlar)
final employerPostingsProvider =
FutureProvider.family<List<JobPosting>, String>((ref, employerId) async {
  final jobBoardService = ref.watch(jobBoardServiceProvider);
  return jobBoardService.getEmployerJobPostings(employerId, page: 1, limit: 100);
});

/// Belirli bir ilanı getir
final jobPostingDetailProvider =
FutureProvider.family<JobPosting, String>((ref, jobPostingId) async {
  final jobBoardService = ref.watch(jobBoardServiceProvider);
  return jobBoardService.getJobPosting(jobPostingId);
});

// ====================================
// Service Provider
// ====================================

/// JobBoardService provider (dependency injection)
final jobBoardServiceProvider = Provider<IJobBoardService>((ref) {
  final supabase = Supabase.instance.client;
  return SupabaseJobBoardService(supabase);
});