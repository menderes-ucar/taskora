import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_exception.dart';
import '../../shared/models/job_model.dart';
import '../../shared/models/user_model.dart';

abstract class ISearchService {
  Future<List<JobModel>> searchJobs({
    required String query,
    String? category,
    double? minBudget,
    double? maxBudget,
    int page = 1,
  });

  Future<List<UserModel>> searchFreelancers({
    required String query,
    String? skill,
    int page = 1,
  });

  Future<List<JobModel>> filterJobs({
    required String status,
    String? category,
    double? minBudget,
    double? maxBudget,
    int page = 1,
  });

  Future<List<JobModel>> getSuggestedJobs({
    required List<String> skills,
    int limit = 10,
  });

  Future<List<UserModel>> getTopFreelancers({int limit = 10});
}

class SupabaseSearchService implements ISearchService {
  final SupabaseClient _supabase;

  SupabaseSearchService(this._supabase);

  @override
  Future<List<JobModel>> searchJobs({
    required String query,
    String? category,
    double? minBudget,
    double? maxBudget,
    int page = 1,
  }) async {
    try {
      const limit = 20;
      int offset = (page - 1) * limit;

      var response = await _supabase
          .from('jobs')
          .select()
          .textSearch('title', query, config: 'english')
          .eq('category', category ?? '')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((job) => JobModel.fromJson(job as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<UserModel>> searchFreelancers({
    required String query,
    String? skill,
    int page = 1,
  }) async {
    try {
      const limit = 20;
      int offset = (page - 1) * limit;

      var response = await _supabase
          .from('users')
          .select()
          .eq('role', 'freelancer')
          .textSearch('name', query, config: 'english')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<JobModel>> filterJobs({
    required String status,
    String? category,
    double? minBudget,
    double? maxBudget,
    int page = 1,
  }) async {
    try {
      const limit = 20;
      int offset = (page - 1) * limit;

      var response = await _supabase
          .from('jobs')
          .select()
          .eq('status', status)
          .eq('category', category ?? '')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((job) => JobModel.fromJson(job as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<JobModel>> getSuggestedJobs({
    required List<String> skills,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select()
          .eq('status', 'open')
          .limit(limit)
          .order('created_at', ascending: false);

      return (response as List)
          .map((job) => JobModel.fromJson(job as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<UserModel>> getTopFreelancers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'freelancer')
          .limit(limit)
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }
}
