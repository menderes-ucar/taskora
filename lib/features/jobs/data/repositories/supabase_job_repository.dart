import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/enums/job_status.dart';
import '../../../../shared/models/job_model.dart';
import 'job_repositories.dart';

class SupabaseJobRepository implements JobRepository {
  final SupabaseClient _supabase;

  SupabaseJobRepository(this._supabase);

  static const String _table = 'jobs';

  @override
  Future<List<JobModel>> getAllJobs() async {
    final response = await _supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => JobModel.fromMap(e)).toList();
  }

  @override
  Future<List<JobModel>> getOpenJobs() async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('status', JobStatus.open.name)
        .order('created_at', ascending: false);

    return (response as List).map((e) => JobModel.fromMap(e)).toList();
  }

  @override
  Future<List<JobModel>> getJobsByEmployer(String employerId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('employer_id', employerId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => JobModel.fromMap(e)).toList();
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return JobModel.fromMap(response);
  }

  @override
  Future<void> addJob(JobModel job) async {
    await _supabase.from(_table).insert(job.toMap());
  }

  @override
  Future<void> updateJob(JobModel updatedJob) async {
    await _supabase
        .from(_table)
        .update(updatedJob.toMap())
        .eq('id', updatedJob.id);
  }

  @override
  Future<void> updateJobStatus(String jobId, JobStatus newStatus) async {
    await _supabase
        .from(_table)
        .update({'status': newStatus.name})
        .eq('id', jobId);
  }

  @override
  Future<void> removeJob(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}