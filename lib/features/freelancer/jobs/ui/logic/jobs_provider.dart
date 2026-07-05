import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/enums/job_status.dart';
import '../../../../../shared/models/job_model.dart';
import '../../data/job_repository_provider.dart';

class JobsNotifier extends AsyncNotifier<List<JobModel>> {
  @override
  Future<List<JobModel>> build() async {
    return _loadJobs();
  }

  Future<List<JobModel>> _loadJobs() async {
    final repository = ref.read(jobRepositoryProvider);
    return repository.getAllJobs();
  }

  Future<void> refreshJobs() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _loadJobs();
    });
  }

  Future<void> addJob(JobModel job) async {
    final repository = ref.read(jobRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.addJob(job);
      return _loadJobs();
    });
  }

  Future<void> updateJob(JobModel updatedJob) async {
    final repository = ref.read(jobRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.updateJob(updatedJob);
      return _loadJobs();
    });
  }

  Future<void> updateJobStatus(String jobId, JobStatus newStatus) async {
    final repository = ref.read(jobRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.updateJobStatus(jobId, newStatus);
      return _loadJobs();
    });
  }

  Future<void> removeJob(String id) async {
    final repository = ref.read(jobRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.removeJob(id);
      return _loadJobs();
    });
  }

  List<JobModel> jobsByEmployer(String employerId) {
    final jobs = state.valueOrNull ?? [];
    return jobs.where((job) => job.employerId == employerId).toList();
  }

  List<JobModel> get openJobs {
    final jobs = state.valueOrNull ?? [];
    return jobs.where((job) => job.status == JobStatus.open).toList();
  }

  JobModel? getById(String id) {
    final jobs = state.valueOrNull ?? [];
    try {
      return jobs.firstWhere((job) => job.id == id);
    } catch (_) {
      return null;
    }
  }
}

final jobsProvider =
AsyncNotifierProvider<JobsNotifier, List<JobModel>>(JobsNotifier.new);

final openJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);

  return jobsAsync.whenData(
        (jobs) => jobs.where((job) => job.status == JobStatus.open).toList(),
  );
});