import '../enums/job_status.dart';
import '../helpers/job_category_helper.dart';

class JobModel {
  final String id;
  final String title;
  final String description;
  final String category;

  final double budgetMin;
  final double budgetMax;

  final List<String> skillsRequired;

  final String duration;
  final String level;

  final String employerId;
  final JobStatus status;
// JobModel içine:
  int get requiredCoins => JobCategoryHelper.getCoinCostByCategory(category);
  final DateTime createdAt;

  const JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budgetMin,
    required this.budgetMax,
    required this.skillsRequired,
    required this.duration,
    required this.level,
    required this.employerId,
    required this.status,
    required this.createdAt,
  });

  JobModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? budgetMin,
    double? budgetMax,
    List<String>? skillsRequired,
    String? duration,
    String? level,
    String? employerId,
    JobStatus? status,
    DateTime? createdAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      duration: duration ?? this.duration,
      level: level ?? this.level,
      employerId: employerId ?? this.employerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',

      budgetMin: (map['budget_min'] as num?)?.toDouble() ?? 0,
      budgetMax: (map['budget_max'] as num?)?.toDouble() ?? 0,

      skillsRequired:
      List<String>.from(map['skills_required'] ?? const []),

      duration: map['duration']?.toString() ?? '',
      level: map['level']?.toString() ?? '',

      employerId: map['employer_id']?.toString() ?? '',

      status: JobStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => JobStatus.open,
      ),

      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'skills_required': skillsRequired,
      'duration': duration,
      'level': level,
      'employer_id': employerId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel.fromMap(json);
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }
}