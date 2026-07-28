import 'package:intl/intl.dart';

/// Rating tipi
enum RatingType {
  freelancer, // Freelancer puanlaması
  employer,   // Employer puanlaması
}

/// Rating/Review kaydı
class RatingModel {
  final String id;
  final String contractId; // İlgili kontrat
  final String giverId; // Puanlayan kişi
  final String recipientId; // Puanlanan kişi
  final RatingType type; // Kimin puanlandığı
  final double rating; // 1-5 yıldız
  final String review; // Yorum
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RatingModel({
    required this.id,
    required this.contractId,
    required this.giverId,
    required this.recipientId,
    required this.type,
    required this.rating,
    required this.review,
    required this.createdAt,
    this.updatedAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] as String? ?? '',
      contractId: map['contract_id'] as String? ?? '',
      giverId: map['giver_id'] as String? ?? '',
      recipientId: map['recipient_id'] as String? ?? '',
      type: _parseRatingType(map['type']),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      review: map['review'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_id': contractId,
      'giver_id': giverId,
      'recipient_id': recipientId,
      'type': type.name,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static RatingType _parseRatingType(dynamic type) {
    if (type is String) {
      return RatingType.values.firstWhere(
            (e) => e.name == type.toLowerCase(),
        orElse: () => RatingType.freelancer,
      );
    }
    return RatingType.freelancer;
  }

  String get typeLabel {
    return type == RatingType.freelancer ? 'Freelancer' : 'Employer';
  }

  String get formattedDate => DateFormat('dd.MM.yyyy').format(createdAt);

  int get starCount => rating.toInt();

  String get ratingLabel {
    if (rating >= 4.5) return 'Mükemmel';
    if (rating >= 4.0) return 'Çok İyi';
    if (rating >= 3.0) return 'İyi';
    if (rating >= 2.0) return 'Orta';
    return 'Kötü';
  }
}

/// Kullanıcı rating özeti (profilde gösterilecek)
class UserRatingSummary {
  final String userId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 puanlarının dağılımı
  final List<RatingModel> recentReviews;

  const UserRatingSummary({
    required this.userId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory UserRatingSummary.fromMap(Map<String, dynamic> map) {
    return UserRatingSummary(
      userId: map['user_id'] as String? ?? '',
      averageRating: (map['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['total_reviews'] as num?)?.toInt() ?? 0,
      ratingDistribution: Map<int, int>.from(
        (map['rating_distribution'] as Map? ?? {}).cast<int, int>(),
      ),
      recentReviews: (map['recent_reviews'] as List? ?? [])
          .map((e) => RatingModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'rating_distribution': ratingDistribution,
      'recent_reviews': recentReviews.map((e) => e.toMap()).toList(),
    };
  }
}
