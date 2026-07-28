import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createReport({
    required String reporterId,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    await _client.from('reports').insert({
      'reporter_id': reporterId,
      'target_id': targetId,
      'reason': reason,
      'description': description,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}