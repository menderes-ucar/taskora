// lib/core/services/analytics_service.dart (Enhanced)

import 'package:firebase_analytics/firebase_analytics.dart';
import '../error/app_exception.dart';

class AnalyticsEvent {
  static const String jobCreated = 'job_created';
  static const String jobViewed = 'job_viewed';
  static const String proposalSent = 'proposal_sent';
  static const String proposalAccepted = 'proposal_accepted';
  static const String contractCreated = 'contract_created';
  static const String paymentMade = 'payment_made';
  static const String messagesSent = 'messages_sent';
  static const String reviewSubmitted = 'review_submitted';
  static const String disputeRaised = 'dispute_raised';
  static const String userSignup = 'user_signup';
  static const String userLogin = 'user_login';
  static const String fundsAdded = 'funds_added';
  static const String fundsWithdrawn = 'funds_withdrawn';
  static const String searchPerformed = 'search_performed';
}

class AnalyticsScreen {
  static const String home = 'home';
  static const String jobList = 'job_list';
  static const String jobDetail = 'job_detail';
  static const String dashboard = 'dashboard';
  static const String messages = 'messages';
  static const String wallet = 'wallet';
  static const String profile = 'profile';
  static const String settings = 'settings';
}

abstract class IAnalyticsService {
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  Future<void> logJobEvent({
    required String jobId,
    required String title,
    required double budget,
  });

  Future<void> logProposalEvent({
    required String proposalId,
    required double bidAmount,
  });

  Future<void> logPaymentEvent({
    required double amount,
    required String paymentMethod,
  });

  Future<void> logUserEvent({
    required String userId,
    required String userRole,
  });

  Future<void> logSearchEvent({
    required String query,
    required int resultCount,
  });

  Future<void> setUserProperties({
    required String userId,
    required String userRole,
    String? joinDate,
  });
}

class FirebaseAnalyticsService implements IAnalyticsService {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService(this._analytics);

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      // Silent fail for analytics
      print('Analytics error: $e');
    }
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  @override
  Future<void> logJobEvent({
    required String jobId,
    required String title,
    required double budget,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvent.jobViewed,
        parameters: {
          'job_id': jobId,
          'job_title': title,
          'budget': budget,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> logProposalEvent({
    required String proposalId,
    required double bidAmount,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvent.proposalSent,
        parameters: {
          'proposal_id': proposalId,
          'bid_amount': bidAmount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> logPaymentEvent({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvent.paymentMade,
        parameters: {
          'amount': amount,
          'payment_method': paymentMethod,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> logUserEvent({
    required String userId,
    required String userRole,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvent.userSignup,
        parameters: {
          'user_id': userId,
          'user_role': userRole,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> logSearchEvent({
    required String query,
    required int resultCount,
  }) async {
    try {
      await logEvent(
        name: AnalyticsEvent.searchPerformed,
        parameters: {
          'search_query': query,
          'result_count': resultCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> setUserProperties({
    required String userId,
    required String userRole,
    String? joinDate,
  }) async {
    try {
      await _analytics.setUserId(id: userId);

      await _analytics.setUserProperty(
        name: 'user_role',
        value: userRole,
      );

      if (joinDate != null) {
        await _analytics.setUserProperty(
          name: 'join_date',
          value: joinDate,
        );
      }
    } catch (e) {
      print('Analytics error: $e');
    }
  }
}
