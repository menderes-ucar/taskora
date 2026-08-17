
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_model.dart';

class SubscriptionService {


  /// Kullanıcının mevcut paketine göre limit aşımı yapıp yapmadığını kontrol eder.
  bool hasReachedLimit({
    required UserModel user,
    required int currentUsageCount,
  }) {
    // İşveren için iş ilanı limiti kontrolü
    if (user.role.name == 'employer') {
      final isLimitExceeded = currentUsageCount >= user.activeJobLimit;
      if (isLimitExceeded) {
        _trackSaaSAction(
          userId: user.id,
          eventName: 'limit_blocked',
          properties: {
            'role': 'employer',
            'limit_type': 'active_jobs',
            'current_tier': user.subscriptionTier,
          },
        );
      }
      return isLimitExceeded;
    }

    // Freelancer için teklif limiti kontrolü
    if (user.role.name == 'freelancer') {
      final isLimitExceeded = currentUsageCount >= user.proposalLimit;
      if (isLimitExceeded) {
        _trackSaaSAction(
          userId: user.id,
          eventName: 'limit_blocked',
          properties: {
            'role': 'freelancer',
            'limit_type': 'proposals',
            'current_tier': user.subscriptionTier,
          },
        );
      }
      return isLimitExceeded;
    }
    return false;
  }

  /// Pakete göre dinamik limit tanımlamaları (Genelde backend'den veya uzaktan yönetilir)
  Map<String, int> getLimitsForTier(String tier) {
    switch (tier) {
      case 'pro':
        return {'jobLimit': 20, 'proposalLimit': 100};
      case 'enterprise':
        return {'jobLimit': 9999, 'proposalLimit': 9999}; // Sınırsız
      case 'free':
      default:
        return {'jobLimit': 3, 'proposalLimit': 10};
    }
  }

  // --- SaaS Analitik ve Takip Sistemi ---
  /// Kullanıcıların abonelik işlemlerini, satın alma adımlarını ve
  /// limite takılma event'lerini analitik platformlarına (PostHog/Mixpanel) gönderir.
  void trackSubscriptionUpgradeAttempt({
    required String userId,
    required String targetTier,
    required String currentTier,
  }) {
    _trackSaaSAction(
      userId: userId,
      eventName: 'subscription_upgrade_click',
      properties: {
        'target_tier': targetTier,
        'current_tier': currentTier,
      },
    );
  }

  /// Satın alma başarılı olduğunda finansal metrik takibi için tetiklenir
  void trackSubscriptionSuccess({
    required String userId,
    required String purchasedTier,
    required double revenue,
  }) {
    _trackSaaSAction(
      userId: userId,
      eventName: 'subscription_purchased',
      properties: {
        'purchased_tier': purchasedTier,
        'revenue': revenue,
        'currency': 'USD',
      },
    );
  }

  /// Ortak analitik event tetikleme motoru (Canlıda PostHog.capture veya Mixpanel.track çağırır)
  void _trackSaaSAction({
    required String userId,
    required String eventName,
    required Map<String, dynamic> properties,
  }) {
    // Proje canlıya çıktığında buraya Sentry breadcrumb'ı ve Analitik SDK'ları bağlanır
    // Örn: PostHog.capture(eventName: eventName, properties: {'distinct_id': userId, ...properties});
    print(' [SaaS Analitik] Event: $eventName | User: $userId | Data: $properties');
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});