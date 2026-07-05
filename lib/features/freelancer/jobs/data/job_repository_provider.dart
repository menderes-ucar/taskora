import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'job_repository.dart';
import 'supabase_job_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseJobRepository(supabase);
});