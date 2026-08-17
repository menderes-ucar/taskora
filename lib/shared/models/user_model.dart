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
  final String? avatarUrl;
  final String? phone;
  // SaaS ve Multi-Tenancy Alanları
  final String? organizationId;
  final String? organizationRole;
  final String subscriptionTier;
  final bool isSubscribed;
  final int activeJobLimit;
  final int proposalLimit;
  final int coins;
  final bool isBanned; // 🚀 EKLENDİ: Ban durumu için eklendi

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.title,
    this.avatarUrl,
    this.phone,
    this.rating,
    this.bio,
    this.coins = 0,
    this.completedJobs,
    this.reviewCount,
    this.skills,
    this.organizationId,
    this.organizationRole,
    this.subscriptionTier = 'free',
    this.isSubscribed = false,
    this.activeJobLimit = 999,
    this.proposalLimit = 10,
    this.isBanned = false, // 🚀 EKLENDİ
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
    String? organizationId,
    String? organizationRole,
    String? subscriptionTier,
    bool? isSubscribed,
    int? activeJobLimit,
    int? proposalLimit,
    String? avatarUrl,
    String? phone,
    int? coins,
    bool? isBanned, // 🚀 EKLENDİ
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
      organizationId: organizationId ?? this.organizationId,
      organizationRole: organizationRole ?? this.organizationRole,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      activeJobLimit: activeJobLimit ?? this.activeJobLimit,
      proposalLimit: proposalLimit ?? this.proposalLimit,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      coins: coins ?? this.coins,
      isBanned: isBanned ?? this.isBanned, // 🚀 EKLENDİ
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: _parseUserRole(map['role']),
      title: map['title'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      bio: map['bio'] as String?,
      completedJobs: map['completed_jobs'] as int?,
      reviewCount: map['review_count'] as int?,
      skills: List<String>.from(map['skills'] as List? ?? []),
      organizationId: map['organization_id'] as String?,
      organizationRole: map['organization_role'] as String?,
      subscriptionTier: map['subscription_tier'] as String? ?? 'free',
      isSubscribed: map['is_subscribed'] as bool? ?? false,
      activeJobLimit: map['active_job_limit'] as int? ?? 999,
      proposalLimit: map['proposal_limit'] as int? ?? 10,
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      isBanned: map['is_banned'] as bool? ?? false, // 🚀 EKLENDİ
    );
  }

  static UserRole _parseUserRole(dynamic role) {
    if (role is String) {
      return UserRole.values.firstWhere(
            (e) => e.name == role.toLowerCase(),
        orElse: () => UserRole.freelancer,
      );
    }
    return UserRole.freelancer;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'title': title,
      'rating': rating,
      'bio': bio,
      'completed_jobs': completedJobs,
      'review_count': reviewCount,
      'skills': skills,
      'organization_id': organizationId,
      'organization_role': organizationRole,
      'subscription_tier': subscriptionTier,
      'is_subscribed': isSubscribed,
      'active_job_limit': activeJobLimit,
      'proposal_limit': proposalLimit,
      'avatar_url': avatarUrl,
      'phone': phone,
      'coins': coins,
      'is_banned': isBanned, // 🚀 EKLENDİ
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);
}

extension UserRoleX on UserModel {
  bool get isAdmin => role.isAdminRole;
  bool get isSuperAdmin => role == UserRole.superAdmin;
}