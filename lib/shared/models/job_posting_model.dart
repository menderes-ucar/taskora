import '../enums/job_board_enums.dart';

/// İş ilanı modeli
class JobPosting {
  final String id;
  final String employerId;
  final String title;
  final String category;
  final WorkType workType;
  final ContractType contractType;
  final String? salaryInfo;
  final String? location;
  final String description;
  final PostingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const JobPosting({
    required this.id,
    required this.employerId,
    required this.title,
    required this.category,
    required this.workType,
    required this.contractType,
    this.salaryInfo,
    this.location,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// copyWith metodu
  JobPosting copyWith({
    String? id,
    String? employerId,
    String? title,
    String? category,
    WorkType? workType,
    ContractType? contractType,
    String? salaryInfo,
    String? location,
    String? description,
    PostingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobPosting(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      title: title ?? this.title,
      category: category ?? this.category,
      workType: workType ?? this.workType,
      contractType: contractType ?? this.contractType,
      salaryInfo: salaryInfo ?? this.salaryInfo,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Map'ten model oluşturma
  factory JobPosting.fromMap(Map<String, dynamic> map) {
    return JobPosting(
      id: map['id']?.toString() ?? '',
      employerId: map['employer_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      workType: WorkType.fromString(map['work_type']?.toString() ?? 'remote'),
      contractType: ContractType.fromString(map['contract_type']?.toString() ?? 'paid'),
      salaryInfo: map['salary_info']?.toString(),
      location: map['location']?.toString(),
      description: map['description']?.toString() ?? '',
      status: PostingStatus.fromString(map['status']?.toString() ?? 'pending'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// Model'i Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employer_id': employerId,
      'title': title,
      'category': category,
      'work_type': workType.name,
      'contract_type': contractType.name,
      'salary_info': salaryInfo,
      'location': location,
      'description': description,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// JSON'dan model oluşturma
  factory JobPosting.fromJson(Map<String, dynamic> json) {
    return JobPosting.fromMap(json);
  }

  /// Model'i JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() =>
      'JobPosting(id: $id, title: $title, employer: $employerId, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is JobPosting &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              employerId == other.employerId &&
              title == other.title &&
              category == other.category &&
              workType == other.workType &&
              contractType == other.contractType &&
              salaryInfo == other.salaryInfo &&
              location == other.location &&
              description == other.description &&
              status == other.status &&
              createdAt == other.createdAt &&
              updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      employerId.hashCode ^
      title.hashCode ^
      category.hashCode ^
      workType.hashCode ^
      contractType.hashCode ^
      salaryInfo.hashCode ^
      location.hashCode ^
      description.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}