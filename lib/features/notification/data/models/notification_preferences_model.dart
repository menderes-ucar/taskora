import '../../../../shared/constants/job_categories.dart';

class NotificationPreferences {
  /// Canonical categories shared with both job creation flows.
  /// Keeping a single source of truth prevents notification preferences from
  /// drifting away from `jobs.category` / `job_postings.category`.
  static List<String> get availableCategories =>
      TaskoraJobCategories.values;

  final String userId;
  final bool pushEnabled;
  final bool jobAlertsEnabled;
  final List<String> jobCategories;

  const NotificationPreferences({
    required this.userId,
    this.pushEnabled = true,
    this.jobAlertsEnabled = true,
    this.jobCategories = const <String>[],
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: map['user_id']?.toString() ?? '',
      pushEnabled: map['push_enabled'] as bool? ?? true,
      jobAlertsEnabled: map['job_alerts_enabled'] as bool? ?? true,
      jobCategories: List<String>.from(map['job_categories'] ?? const <String>[]),
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? jobAlertsEnabled,
    List<String>? jobCategories,
  }) {
    return NotificationPreferences(
      userId: userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      jobAlertsEnabled: jobAlertsEnabled ?? this.jobAlertsEnabled,
      jobCategories: jobCategories ?? this.jobCategories,
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'push_enabled': pushEnabled,
    'job_alerts_enabled': jobAlertsEnabled,
    'job_categories': jobCategories,
  };
}
