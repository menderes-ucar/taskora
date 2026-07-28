import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/coin/data/services/coin_service.dart';
import '../../features/freelancer/presentation/pages/freelancer_dashboard_page.dart';
import '../services/rating_service.dart';


/// 1. SupabaseClient'ı ayrı bir provider yapmak test edilebilirlik ve mimari için daha sağlıklıdır.
@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

/// 2. `CoinServiceRef` yerine genel `Ref` kullanarak build_runner öncesi IDE hatalarını önleyebilirsiniz.
@riverpod
SupabaseCoinService coinService(Ref ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseCoinService(supabase);
}

@riverpod
SupabaseRatingService ratingService(Ref ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseRatingService(supabase);
}