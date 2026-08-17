import '../enums/contract_status.dart';
import '../enums/payment_status.dart';

class ContractModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String employerId;
  final String freelancerId;
  final String freelancerName;
  final double agreedAmount;
  final int deliveryDays;
  final ContractStatus status;
  final DateTime createdAt;
  final PaymentStatus paymentStatus;
  final bool employerRated;
  final bool freelancerRated;
  final double escrowAmount;
  final double platformFee;
  final double freelancerEarning;
  final int revisionCount;
  final int maxRevisionCount;
  final bool autoReleaseEnabled;
  final bool disputeOpened;
  final bool isLate;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? dueAt;
  final DateTime? autoReleaseAt;
  final DateTime? lastActivityAt;

  const ContractModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.employerId,
    required this.freelancerId,
    required this.freelancerName,
    required this.agreedAmount,
    required this.deliveryDays,
    required this.status,
    required this.createdAt,
    required this.paymentStatus,
    this.employerRated = false,
    this.freelancerRated = false,
    this.escrowAmount = 0,
    this.platformFee = 0,
    this.freelancerEarning = 0,
    this.revisionCount = 0,
    this.maxRevisionCount = 3,
    this.autoReleaseEnabled = true,
    this.disputeOpened = false,
    this.isLate = false,
    this.startedAt,
    this.submittedAt,
    this.approvedAt,
    this.completedAt,
    this.cancelledAt,
    this.dueAt,
    this.autoReleaseAt,
    this.lastActivityAt,
  });

  /// Validates financial calculations
  bool get isFinanciallyConsistent {
    const epsilon = 0.01; // Allow for rounding errors
    final total = (platformFee + freelancerEarning).abs();
    final expected = agreedAmount.abs();
    return (total - expected).abs() < epsilon;
  }

  /// Checks if contract timeline has been violated
  bool get isTimelineViolated {
    if (!isLate) return false;
    if (dueAt == null) return false;
    return DateTime.now().toUtc().isAfter(dueAt!.toUtc());
  }

  /// Checks if auto-release should trigger
  bool get shouldAutoRelease {
    if (!autoReleaseEnabled) return false;
    if (autoReleaseAt == null) return false;
    if (status != ContractStatus.approved) return false;
    return DateTime.now().toUtc().isAfter(autoReleaseAt!.toUtc());
  }

  /// Checks if contract has both ratings
  bool get isFullyRated {
    return employerRated && freelancerRated;
  }

  /// Gets time remaining until due date
  Duration? get timeRemaining {
    if (dueAt == null) return null;
    final now = DateTime.now().toUtc();
    final due = dueAt!.toUtc();
    if (now.isAfter(due)) return Duration.zero;
    return due.difference(now);
  }

  ContractModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? employerId,
    String? freelancerId,
    String? freelancerName,
    double? agreedAmount,
    int? deliveryDays,
    ContractStatus? status,
    DateTime? createdAt,
    PaymentStatus? paymentStatus,
    bool? employerRated,
    bool? freelancerRated,
    double? escrowAmount,
    double? platformFee,
    double? freelancerEarning,
    int? revisionCount,
    int? maxRevisionCount,
    bool? autoReleaseEnabled,
    bool? disputeOpened,
    bool? isLate,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? dueAt,
    DateTime? autoReleaseAt,
    DateTime? lastActivityAt,
  }) {
    return ContractModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      employerId: employerId ?? this.employerId,
      freelancerId: freelancerId ?? this.freelancerId,
      freelancerName: freelancerName ?? this.freelancerName,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      employerRated: employerRated ?? this.employerRated,
      freelancerRated: freelancerRated ?? this.freelancerRated,
      escrowAmount: escrowAmount ?? this.escrowAmount,
      platformFee: platformFee ?? this.platformFee,
      freelancerEarning: freelancerEarning ?? this.freelancerEarning,
      revisionCount: revisionCount ?? this.revisionCount,
      maxRevisionCount: maxRevisionCount ?? this.maxRevisionCount,
      autoReleaseEnabled: autoReleaseEnabled ?? this.autoReleaseEnabled,
      disputeOpened: disputeOpened ?? this.disputeOpened,
      isLate: isLate ?? this.isLate,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      dueAt: dueAt ?? this.dueAt,
      autoReleaseAt: autoReleaseAt ?? this.autoReleaseAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: (map['id'] ?? '').toString(),
      jobId: (map['job_id'] ?? '').toString(),
      jobTitle: (map['job_title'] ?? 'İlan').toString(),
      employerId: (map['employer_id'] ?? '').toString(),
      freelancerId: (map['freelancer_id'] ?? '').toString(),
      freelancerName: (map['freelancer_name'] ?? 'Freelancer').toString(),
      agreedAmount: (map['agreed_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryDays: (map['delivery_days'] as int?) ?? 1,
      status: ContractStatusX.fromString(map['status']?.toString()),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now().toUtc(),
      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == map['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      employerRated: map['employer_rated'] as bool? ?? false,
      freelancerRated: map['freelancer_rated'] as bool? ?? false,
      escrowAmount: (map['escrow_amount'] as num?)?.toDouble() ?? 0,
      platformFee: (map['platform_fee'] as num?)?.toDouble() ?? 0,
      freelancerEarning: (map['freelancer_earning'] as num?)?.toDouble() ?? 0,
      revisionCount: map['revision_count'] ?? 0,
      maxRevisionCount: map['max_revision_count'] ?? 3,
      autoReleaseEnabled: map['auto_release_enabled'] ?? true,
      disputeOpened: map['dispute_opened'] ?? false,
      isLate: map['is_late'] ?? false,
      startedAt: _parseDateTime(map['started_at']),
      submittedAt: _parseDateTime(map['submitted_at']),
      approvedAt: _parseDateTime(map['approved_at']),
      completedAt: _parseDateTime(map['completed_at']),
      cancelledAt: _parseDateTime(map['cancelled_at']),
      dueAt: _parseDateTime(map['due_at']),
      autoReleaseAt: _parseDateTime(map['auto_release_at']),
      lastActivityAt: _parseDateTime(map['last_activity_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'job_title': jobTitle,
      'employer_id': employerId,
      'freelancer_id': freelancerId,
      'freelancer_name': freelancerName,
      'agreed_amount': agreedAmount,
      'delivery_days': deliveryDays,
      'status': status.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'payment_status': paymentStatus.name,
      'employer_rated': employerRated,
      'freelancer_rated': freelancerRated,
      'escrow_amount': escrowAmount,
      'platform_fee': platformFee,
      'freelancer_earning': freelancerEarning,
      'revision_count': revisionCount,
      'max_revision_count': maxRevisionCount,
      'auto_release_enabled': autoReleaseEnabled,
      'dispute_opened': disputeOpened,
      'is_late': isLate,
      'started_at': startedAt?.toUtc().toIso8601String(),
      'submitted_at': submittedAt?.toUtc().toIso8601String(),
      'approved_at': approvedAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
      'due_at': dueAt?.toUtc().toIso8601String(),
      'auto_release_at': autoReleaseAt?.toUtc().toIso8601String(),
      'last_activity_at': lastActivityAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'job_id': jobId,
      'job_title': jobTitle,
      'employer_id': employerId,
      'freelancer_id': freelancerId,
      'freelancer_name': freelancerName,
      'agreed_amount': agreedAmount,
      'delivery_days': deliveryDays,
      'status': status.name,
      'payment_status': paymentStatus.name,
      'employer_rated': employerRated,
      'freelancer_rated': freelancerRated,
      'escrow_amount': escrowAmount,
      'platform_fee': platformFee,
      'freelancer_earning': freelancerEarning,
      'revision_count': revisionCount,
      'max_revision_count': maxRevisionCount,
      'auto_release_enabled': autoReleaseEnabled,
      'dispute_opened': disputeOpened,
      'is_late': isLate,
      'started_at': startedAt?.toUtc().toIso8601String(),
      'submitted_at': submittedAt?.toUtc().toIso8601String(),
      'approved_at': approvedAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
      'due_at': dueAt?.toUtc().toIso8601String(),
      'auto_release_at': autoReleaseAt?.toUtc().toIso8601String(),
      'last_activity_at': lastActivityAt?.toUtc().toIso8601String(),
    };
  }
}
