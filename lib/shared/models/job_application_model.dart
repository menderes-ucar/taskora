import '../enums/job_board_enums.dart';

/// İş başvurusu modeli
class JobApplication {
  final String id;
  final String jobPostingId;
  final String freelancerId;
  final String coverLetter;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const JobApplication({
    required this.id,
    required this.jobPostingId,
    required this.freelancerId,
    required this.coverLetter,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// copyWith metodu
  JobApplication copyWith({
    String? id,
    String? jobPostingId,
    String? freelancerId,
    String? coverLetter,
    ApplicationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobPostingId: jobPostingId ?? this.jobPostingId,
      freelancerId: freelancerId ?? this.freelancerId,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Map'ten model oluşturma
  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id']?.toString() ?? '',
      jobPostingId: map['job_posting_id']?.toString() ?? '',
      freelancerId: map['freelancer_id']?.toString() ?? '',
      coverLetter: map['cover_letter']?.toString() ?? '',
      status: ApplicationStatus.fromString(map['status']?.toString() ?? 'pending'),
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
      'job_posting_id': jobPostingId,
      'freelancer_id': freelancerId,
      'cover_letter': coverLetter,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// JSON'dan model oluşturma
  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication.fromMap(json);
  }

  /// Model'i JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() =>
      'JobApplication(id: $id, jobPosting: $jobPostingId, freelancer: $freelancerId, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is JobApplication &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              jobPostingId == other.jobPostingId &&
              freelancerId == other.freelancerId &&
              coverLetter == other.coverLetter &&
              status == other.status &&
              createdAt == other.createdAt &&
              updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      jobPostingId.hashCode ^
      freelancerId.hashCode ^
      coverLetter.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}