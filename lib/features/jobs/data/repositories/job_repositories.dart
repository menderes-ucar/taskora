import '../../../../shared/enums/job_status.dart';
import '../../../../shared/models/job_model.dart';

abstract class JobRepository {
  Future<List<JobModel>> getAllJobs();
  Future<List<JobModel>> getOpenJobs();
  Future<List<JobModel>> getJobsByEmployer(String employerId);
  Future<JobModel?> getJobById(String id);
  Future<void> addJob(JobModel job);
  Future<void> updateJob(JobModel updatedJob);
  Future<void> updateJobStatus(String jobId, JobStatus newStatus);
  Future<void> removeJob(String id);
}