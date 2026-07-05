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
  });

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
    );
  }

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      jobTitle: map['job_title'] as String,
      employerId: map['employer_id'] as String,
      freelancerId: map['freelancer_id'] as String,
      freelancerName: map['freelancer_name'] as String,
      agreedAmount: (map['agreed_amount'] as num).toDouble(),
      deliveryDays: map['delivery_days'] as int,
      status: ContractStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => ContractStatus.active,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      paymentStatus: PaymentStatus.values.firstWhere(
            (e) => e.name == map['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
    );
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
      'created_at': createdAt.toIso8601String(),
      'payment_status': paymentStatus.name,
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
    };
  }
}