import '../enums/job_status.dart';

class JobModel {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final double budget;
  final String category;
  final int deliveryDays;
  final JobStatus status;
  final DateTime createdAt;

  const JobModel({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.budget,
    required this.category,
    required this.deliveryDays,
    required this.status,
    required this.createdAt,
  });

  JobModel copyWith({
    String? id,
    String? employerId,
    String? title,
    String? description,
    double? budget,
    String? category,
    int? deliveryDays,
    JobStatus? status,
    DateTime? createdAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      title: title ?? this.title,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      category: category ?? this.category,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id'] as String,
      employerId: map['employer_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      budget: (map['budget'] as num).toDouble(),
      category: map['category'] as String,
      deliveryDays: map['delivery_days'] as int,
      status: JobStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => JobStatus.open,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employer_id': employerId,
      'title': title,
      'description': description,
      'budget': budget,
      'category': category,
      'delivery_days': deliveryDays,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}