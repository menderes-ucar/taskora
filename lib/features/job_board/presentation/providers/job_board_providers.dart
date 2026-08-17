import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/job_board_service.dart';
import '../../../../shared/models/job_posting_model.dart';
import '../../../../shared/models/job_application_model.dart';
import '../../../../shared/enums/job_board_enums.dart';

// Service Provider
final jobBoardServiceProvider = Provider<IJobBoardService>((ref) {
  return SupabaseJobBoardService(Supabase.instance.client);
});


final approvedJobPostingsStreamProvider = StreamProvider.autoDispose<List<JobPosting>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('job_postings')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data
      .map((json) => JobPosting.fromMap(json))
      .where((posting) => posting.status == PostingStatus.approved) // 🚀 Filtreleme Dart tarafına çekildi
      .toList());
});

// 🚀 REALTIME: Admin Onayı Bekleyen İlanları Dinleyen StreamProvider (Garantili Çalışan Versiyon)
final pendingJobPostingsStreamProvider = StreamProvider.autoDispose<List<JobPosting>>((ref) {
  final supabase = Supabase.instance.client;

  // Realtime stream kanalı açılır
  return supabase
      .from('job_postings')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) {
    return data
        .map((json) => JobPosting.fromMap(json))
        .where((posting) => posting.status == PostingStatus.pending)
        .toList();
  });
});
// İşverenin kendi ilanlarını canlı dinleme
final employerJobPostingsStreamProvider = StreamProvider.autoDispose.family<List<JobPosting>, String>((ref, employerId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('job_postings')
      .stream(primaryKey: ['id'])
      .eq('employer_id', employerId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => JobPosting.fromMap(json)).toList());
});

// Bir ilana gelen başvuruları canlı dinleme
final jobApplicationsStreamProvider = StreamProvider.autoDispose.family<List<JobApplication>, String>((ref, jobPostingId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('job_applications')
      .stream(primaryKey: ['id'])
      .eq('job_posting_id', jobPostingId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => JobApplication.fromMap(json)).toList());
});
// 🚀 REALTIME: Freelancer'ın Kendi Başvurularını Dinleyen StreamProvider Family
final freelancerApplicationsStreamProvider = StreamProvider.autoDispose.family<List<JobApplication>, String>((ref, freelancerId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('job_applications')
      .stream(primaryKey: ['id'])
      .eq('freelancer_id', freelancerId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => JobApplication.fromMap(json)).toList());
});