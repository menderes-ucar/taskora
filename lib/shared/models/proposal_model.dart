import '../enums/proposal_status.dart';

class ProposalModel {
  final String id;
  final String jobId;
  final String freelancerId;
  final String freelancerName;
  final double amount;
  final int deliveryDays;
  final String coverLetter;
  final ProposalStatus status;
  final DateTime createdAt;

  const ProposalModel({
    required this.id,
    required this.jobId,
    required this.freelancerId,
    required this.freelancerName,
    required this.amount,
    required this.deliveryDays,
    required this.coverLetter,
    required this.status,
    required this.createdAt,
  });

  ProposalModel copyWith({
    String? id,
    String? jobId,
    String? freelancerId,
    String? freelancerName,
    double? amount,
    int? deliveryDays,
    String? coverLetter,
    ProposalStatus? status,
    DateTime? createdAt,
  }) {
    return ProposalModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      freelancerId: freelancerId ?? this.freelancerId,
      freelancerName: freelancerName ?? this.freelancerName,
      amount: amount ?? this.amount,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProposalModel.fromMap(Map<String, dynamic> map) {
    return ProposalModel(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      freelancerId: map['freelancer_id'] as String,
      freelancerName: map['freelancer_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      deliveryDays: map['delivery_days'] as int,
      coverLetter: map['cover_letter'] as String,
      status: ProposalStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => ProposalStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'freelancer_id': freelancerId,
      'freelancer_name': freelancerName,
      'amount': amount,
      'delivery_days': deliveryDays,
      'cover_letter': coverLetter,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'job_id': jobId,
      'freelancer_id': freelancerId,
      'freelancer_name': freelancerName,
      'amount': amount,
      'delivery_days': deliveryDays,
      'cover_letter': coverLetter,
      'status': status.name,
    };
  }
}