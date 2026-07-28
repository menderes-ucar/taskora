import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/enums/job_status.dart';
import '../../../../shared/models/job_model.dart';
import '../../data/repositories/job_repositories_provider.dart';

class JobsNotifier extends AsyncNotifier<List<JobModel>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<List<JobModel>> build() async {
    _initRealtimeStream();
    return ref.read(jobRepositoryProvider).getAllJobs();
  }

  void _initRealtimeStream() {
    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
      final jobs = data.map((map) => JobModel.fromMap(map)).toList();
      state = AsyncValue.data(jobs);
    }, onError: (error, stack) {
      state = AsyncValue.error(error, stack);
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  /// 🚀 EKLENEN METOD: RefreshIndicator için Manuel İlan Yenileme Fonksiyonu
  Future<void> refreshJobs() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(jobRepositoryProvider).getAllJobs();
    });
  }

  JobModel? getById(String id) {
    final jobs = state.valueOrNull ?? [];
    try {
      return jobs.firstWhere((job) => job.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addJob(JobModel job) async {
    final repository = ref.read(jobRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addJob(job);
      return repository.getAllJobs();
    });
  }

  Future<void> updateJob(String jobId, JobModel updatedJob) async {
    final repository = ref.read(jobRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateJob(updatedJob);
      return repository.getAllJobs();
    });
  }

  Future<void> removeJob(String jobId) async {
    final repository = ref.read(jobRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.removeJob(jobId);
      return repository.getAllJobs();
    });
  }

  Future<void> updateJobStatus(String jobId, JobStatus newStatus) async {
    final repository = ref.read(jobRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateJobStatus(jobId, newStatus);
      return repository.getAllJobs();
    });
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<JobModel>>(
  JobsNotifier.new,
);

final openJobsProvider = Provider<List<JobModel>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  return jobsAsync.maybeWhen(
    data: (jobs) => jobs.where((j) => j.status == JobStatus.open).toList(),
    orElse: () => [],
  );
});