import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/rating_model.dart';

abstract class IRatingService {
  // Rating işlemleri
  Future<RatingModel?> getRatingByContractId(String contractId);
  Future<List<RatingModel>> getUserRatings(String userId, RatingType type);
  Future<void> createRating(RatingModel rating);
  Future<void> updateRating(RatingModel rating);

  // Özet istatistikler
  Future<UserRatingSummary> getUserRatingSummary(String userId);
  Future<double> getAverageRating(String userId);
  Future<int> getTotalReviewCount(String userId);
  Future<List<RatingModel>> getRecentReviews(String userId, {int limit = 5});
}

class SupabaseRatingService implements IRatingService {
  final SupabaseClient _supabase;

  SupabaseRatingService(this._supabase);

  @override
  Future<RatingModel?> getRatingByContractId(String contractId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('contract_id', contractId)
          .maybeSingle();

      if (response == null) return null;
      return RatingModel.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ getRatingByContractId error: $e');
      return null;
    }
  }

  @override
  Future<List<RatingModel>> getUserRatings(String userId, RatingType type) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('recipient_id', userId)
          .eq('type', type.name)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => RatingModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getUserRatings error: $e');
      return [];
    }
  }

  @override
  Future<void> createRating(RatingModel rating) async {
    try {
      // Rating kaydı oluştur
      await _supabase.from('ratings').insert(rating.toMap());

      // User'ın average rating'ini güncelle
      await _updateUserAverageRating(rating.recipientId);
    } catch (e) {
      print('❌ createRating error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateRating(RatingModel rating) async {
    try {
      await _supabase
          .from('ratings')
          .update(rating.toMap())
          .eq('id', rating.id);

      // User'ın average rating'ini güncelle
      await _updateUserAverageRating(rating.recipientId);
    } catch (e) {
      print('❌ updateRating error: $e');
      rethrow;
    }
  }

  @override
  Future<UserRatingSummary> getUserRatingSummary(String userId) async {
    try {
      // Tüm ratingleri al
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      final ratings = (response as List<dynamic>)
          .map((json) => RatingModel.fromMap(json as Map<String, dynamic>))
          .toList();

      // Ortalama rating hesapla
      double averageRating = 0.0;
      if (ratings.isNotEmpty) {
        final sum = ratings.fold<double>(0, (acc, r) => acc + r.rating);
        averageRating = sum / ratings.length;
      }

      // Rating dağılımını hesapla
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((r) => r.rating.toInt() == i).length;
      }

      // Son 5 rating'i al
      final recentReviews = ratings.take(5).toList();

      return UserRatingSummary(
        userId: userId,
        averageRating: double.parse(averageRating.toStringAsFixed(1)),
        totalReviews: ratings.length,
        ratingDistribution: ratingDistribution,
        recentReviews: recentReviews,
      );
    } catch (e) {
      print('❌ getUserRatingSummary error: $e');
      return UserRatingSummary(
        userId: userId,
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        recentReviews: [],
      );
    }
  }

  @override
  Future<double> getAverageRating(String userId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('recipient_id', userId);

      if ((response as List).isEmpty) return 0.0;

      final ratings = response
          .map((json) => RatingModel.fromMap(json as Map<String, dynamic>))
          .toList();

      final sum = ratings.fold<double>(0, (acc, r) => acc + r.rating);
      final average = sum / ratings.length;

      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      print('❌ getAverageRating error: $e');
      return 0.0;
    }
  }

  @override
  Future<int> getTotalReviewCount(String userId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('recipient_id', userId);

      return (response as List).length;
    } catch (e) {
      print('❌ getTotalReviewCount error: $e');
      return 0;
    }
  }

  @override
  Future<List<RatingModel>> getRecentReviews(String userId,
      {int limit = 5}) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) => RatingModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getRecentReviews error: $e');
      return [];
    }
  }

  // Yardımcı method: User average rating'ini güncelle
  Future<void> _updateUserAverageRating(String userId) async {
    try {
      final average = await getAverageRating(userId);
      final count = await getTotalReviewCount(userId);

      await _supabase
          .from('users')
          .update({
        'rating': average,
        'review_count': count,
      })
          .eq('id', userId);
    } catch (e) {
      print('⚠️ _updateUserAverageRating error: $e');
    }
  }
}
