import '../../../../shared/data/mock_data.dart';
import '../../../../shared/enums/job_status.dart';
import '../../../../shared/models/job_model.dart';
import 'job_repository.dart';

class MockJobRepository implements JobRepository {
  final List<JobModel> _jobs = List<JobModel>.from(MockData.jobs);

  @override
  Future<List<JobModel>> getAllJobs() async {
    return List<JobModel>.from(_jobs);
  }

  @override
  Future<List<JobModel>> getOpenJobs() async {
    return _jobs.where((job) => job.status == JobStatus.open).toList();
  }

  @override
  Future<List<JobModel>> getJobsByEmployer(String employerId) async {
    return _jobs.where((job) => job.employerId == employerId).toList();
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    try {
      return _jobs.firstWhere((job) => job.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addJob(JobModel job) async {
    _jobs.insert(0, job);
  }

  @override
  Future<void> updateJob(JobModel updatedJob) async {
    final index = _jobs.indexWhere((job) => job.id == updatedJob.id);
    if (index == -1) return;

    _jobs[index] = updatedJob;
  }

  @override
  Future<void> updateJobStatus(String jobId, JobStatus newStatus) async {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;

    _jobs[index] = _jobs[index].copyWith(status: newStatus);
  }

  @override
  Future<void> removeJob(String id) async {
    _jobs.removeWhere((job) => job.id == id);
  }
}