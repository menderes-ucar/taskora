
import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_exception.dart';

class ReviewModel {
  final String id;
  final String contractId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.contractId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'],
    contractId: json['contract_id'],
    reviewerId: json['reviewer_id'],
    revieweeId: json['reviewee_id'],
    rating: json['rating'],
    comment: json['comment'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contract_id': contractId,
    'reviewer_id': reviewerId,
    'reviewee_id': revieweeId,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
  };
}

abstract class IReviewService {
  Future<List<ReviewModel>> getReviewsForUser(String userId);
  Future<double> getAverageRating(String userId);
  Future<ReviewModel> createReview(ReviewModel review);
  Future<bool> hasUserReviewed(String reviewerId, String contractId);
}

class SupabaseReviewService implements IReviewService {
  final SupabaseClient _supabase;

  SupabaseReviewService(this._supabase);

  @override
  Future<List<ReviewModel>> getReviewsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false);

      return List<ReviewModel>.from(
        (response as List).map((review) => ReviewModel.fromJson(review as Map<String, dynamic>)),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<double> getAverageRating(String userId) async {
    try {
      final reviews = await getReviewsForUser(userId);

      if (reviews.isEmpty) return 0.0;

      final sum = reviews.fold<int>(0, (sum, review) => sum + review.rating);
      return sum / reviews.length;
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<ReviewModel> createReview(ReviewModel review) async {
    try {
      // Check if already reviewed
      final existing = await _supabase
          .from('reviews')
          .select()
          .eq('contract_id', review.contractId)
          .eq('reviewer_id', review.reviewerId)
          .maybeSingle();

      if (existing != null) {
        throw AppException(
          message: 'You have already reviewed this contract',
          type: AppExceptionType.validation,
        );
      }

      // Validate rating
      if (review.rating < 1 || review.rating > 5) {
        throw AppException(
          message: 'Rating must be between 1 and 5',
          type: AppExceptionType.validation,
        );
      }

      final reviewData = {
        'contract_id': review.contractId,
        'reviewer_id': review.reviewerId,
        'reviewee_id': review.revieweeId,
        'rating': review.rating,
        'comment': review.comment,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('reviews')
          .insert(reviewData)
          .select()
          .single();

      return ReviewModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<bool> hasUserReviewed(String reviewerId, String contractId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('contract_id', contractId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }
}
