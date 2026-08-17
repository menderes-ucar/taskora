import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/job_board_service.dart';
import '../../../../shared/enums/job_board_enums.dart';
import '../../../../shared/models/job_application_model.dart';
import '../../../../shared/models/job_posting_model.dart';
import 'job_postings_provider.dart';

// ====================================
// Job Applications Notifier
// ====================================

class JobApplicationsNotifier
    extends AsyncNotifier<List<JobApplication>> {
  late IJobBoardService _jobBoardService;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<List<JobApplication>> build() async {
    _jobBoardService = ref.watch(jobBoardServiceProvider);

    // Cleanup subscription when provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // İlk yükleme (tüm başvurular)
    // NOT: Bu provider admin/işveren paneli için kullanılır
    // Freelancer'lar kendi başvurularını görmek için myApplicationsProvider kullanır
    final initialData = await _getAllApplications();

    // Realtime dinlemesini başlat
    _initRealtimeStream();

    return initialData;
  }

  /// Supabase'den tüm başvuruları çek
  Future<List<JobApplication>> _getAllApplications() async {
    // Tüm başvuruları sayfalı şekilde çek
    // İdeal olarak admin panelinde kullanılır
    final applications = <JobApplication>[];
    int page = 1;
    const limit = 100;

    while (true) {
      final batch =
      await _jobBoardService.getJobApplications('', page: page, limit: limit);
      if (batch.isEmpty) break;
      applications.addAll(batch);
      page++;
    }

    return applications;
  }

  /// Supabase'den canlı dinleme başlat
  /// Yeni başvuru geldiğinde, status değiştiğinde otomatik güncelleme
  void _initRealtimeStream() {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('job_applications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            final applications = data
                .map((map) => JobApplication.fromMap(map))
                .toList();
        state = AsyncValue.data(applications);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  // ====================================
  // CRUD Operasyonları
  // ====================================

  /// Freelancer: İlana başvur
  /// ⚠️ ÖNEMLİ: Coin düşmesi otomatik yapılır!
  /// Realtime otomatik güncelleme tetiklenir
  Future<JobApplication> applyToPosting({
    required String jobPostingId,
    required String freelancerId,
    required String coverLetter,
    required double coinCost,
  }) async {
    try {
      state = const AsyncValue.loading();

      final application = await _jobBoardService.applyToJobPosting(
        jobPostingId: jobPostingId,
        freelancerId: freelancerId,
        coverLetter: coverLetter,
        coinCost: coinCost,
      );

      // Realtime stream otomatik güncelleyecek
      return application;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// İşveren: Başvuru durumunu güncelle (reviewed/accepted/rejected)
  /// Freelancer'a otomatik bildirim gönderilir
  /// Realtime otomatik güncelleme
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
  }) async {
    try {
      state = const AsyncValue.loading();

      await _jobBoardService.updateApplicationStatus(
        applicationId: applicationId,
        newStatus: newStatus,
      );

      // Realtime stream otomatik güncelleyecek
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Freelancer: Başvurusunu iptal et (sadece pending)
  /// ⚠️ NOT: Coin geri VERİLMEZ!
  Future<void> withdrawApplication({
    required String applicationId,
    required String freelancerId,
  }) async {
    try {
      state = const AsyncValue.loading();

      await _jobBoardService.withdrawApplication(
        applicationId,
        freelancerId,
      );

      // Realtime stream otomatik güncelleyecek
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // ====================================
  // Helper Metodları
  // ====================================

  /// ID'ye göre başvuruyu getir (mevcut verilerden)
  JobApplication? getApplicationById(String id) {
    final applications = state.valueOrNull ?? [];
    try {
      return applications.firstWhere((app) => app.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tüm başvuruları manuel olarak yenile
  Future<void> refreshApplications() async {
    try {
      state = const AsyncValue.loading();
      final refreshedData = await _getAllApplications();
      state = AsyncValue.data(refreshedData);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// ====================================
// Providers
// ====================================

/// Ana provider: Tüm iş başvuruları (Realtime)
/// NOT: Başlamda tüm başvuruları yükler, sonra realtime dinler
final jobApplicationsProvider = AsyncNotifierProvider<
    JobApplicationsNotifier,
    List<JobApplication>>(
  JobApplicationsNotifier.new,
);

/// Belirli bir iş ilanına gelen başvuruları filtrele
final jobApplicationsForPostingProvider =
Provider.family<List<JobApplication>, String>((ref, jobPostingId) {
  final applicationsAsync = ref.watch(jobApplicationsProvider);
  return applicationsAsync.maybeWhen(
    data: (applications) => applications
        .where((app) => app.jobPostingId == jobPostingId)
        .toList(),
    orElse: () => [],
  );
});

/// Belirli bir iş ilanına gelen başvuruları duruma göre filtrele
final jobApplicationsForPostingByStatusProvider =
Provider.family<List<JobApplication>, ({String jobPostingId, ApplicationStatus status})>(
      (ref, params) {
    final applicationsAsync = ref.watch(jobApplicationsProvider);
    return applicationsAsync.maybeWhen(
      data: (applications) => applications
          .where((app) =>
      app.jobPostingId == params.jobPostingId &&
          app.status == params.status)
          .toList(),
      orElse: () => [],
    );
  },
);

/// Freelancer'ın tüm başvuruları
final myApplicationsProvider =
Provider.family<List<JobApplication>, String>((ref, freelancerId) {
  final applicationsAsync = ref.watch(jobApplicationsProvider);
  return applicationsAsync.maybeWhen(
    data: (applications) => applications
        .where((app) => app.freelancerId == freelancerId)
        .toList(),
    orElse: () => [],
  );
});

/// Freelancer'ın belirli bir iş ilanına başvurusu var mı?
final hasAppliedToPostingProvider = Provider.family<bool, ({String freelancerId, String jobPostingId})>(
      (ref, params) {
    final applicationsAsync = ref.watch(jobApplicationsProvider);
    return applicationsAsync.maybeWhen(
      data: (applications) => applications.any(
            (app) =>
        app.freelancerId == params.freelancerId &&
            app.jobPostingId == params.jobPostingId,
      ),
      orElse: () => false,
    );
  },
);

/// Freelancer'ın belirli bir iş ilanına başvurusunu getir
final freelancerApplicationForPostingProvider =
Provider.family<JobApplication?, ({String freelancerId, String jobPostingId})>(
      (ref, params) {
    final applicationsAsync = ref.watch(jobApplicationsProvider);
    return applicationsAsync.maybeWhen(
      data: (applications) {
        try {
          return applications.firstWhere(
                (app) =>
            app.freelancerId == params.freelancerId &&
                app.jobPostingId == params.jobPostingId,
          );
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );
  },
);

/// İş ilanı detayı + gelen başvurular (birlikte)
final jobPostingWithApplicationsProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, jobPostingId) async {
  final jobBoardService = ref.watch(jobBoardServiceProvider);
  return jobBoardService.getJobPostingWithApplications(jobPostingId);
});

/// Freelancer'ın tüm başvurularını yapısal veriyle getir
final myApplicationsDetailedProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, freelancerId) async {
    final applications = ref.watch(myApplicationsProvider(freelancerId));
    final jobPostings = ref.watch(jobPostingsProvider);

    return jobPostings.maybeWhen(
      data: (postings) {
        return applications
            .map((app) {
          final posting = postings.firstWhere(
                (p) => p.id == app.jobPostingId,
            orElse: () => JobPosting(
              id: app.jobPostingId,
              employerId: '',
              title: 'Silinmiş İlan',
              category: '',
              workType: WorkType.remote,
              contractType: ContractType.paid,
              description: '',
              status: PostingStatus.closed,
              createdAt: DateTime.now(),
            ),
          );

          return {
            'application': app,
            'posting': posting,
          };
        })
            .toList();
      },
      orElse: () => [],
    );
  },
);