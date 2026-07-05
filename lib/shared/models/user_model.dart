import '../enums/user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? title;
  final double? rating;
  final String? bio;
  final int? completedJobs;
  final int? reviewCount;
  final List<String>? skills;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.title,
    this.rating,
    this.bio,
    this.completedJobs,
    this.reviewCount,
    this.skills,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? title,
    double? rating,
    String? bio,
    int? completedJobs,
    int? reviewCount,
    List<String>? skills,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      title: title ?? this.title,
      rating: rating ?? this.rating,
      bio: bio ?? this.bio,
      completedJobs: completedJobs ?? this.completedJobs,
      reviewCount: reviewCount ?? this.reviewCount,
      skills: skills ?? this.skills,
    );
  }
}