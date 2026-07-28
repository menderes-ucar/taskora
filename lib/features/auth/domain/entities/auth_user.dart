import '../../../../shared/enums/user_role.dart';

class AuthUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool emailVerified;
  final String? avatar;

  // Freelancer & Employer Özel Alanları
  final String? title;
  final String? companyName;
  final String? industry;
  final double? hourlyRate;

  // SaaS & Ekonomi Alanları
  final int coins;
  final String subscriptionTier;
  final bool isSubscribed;
  final int activeJobLimit;
  final int proposalLimit;

  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.emailVerified,
    this.avatar,
    this.title,
    this.companyName,
    this.industry,
    this.hourlyRate,
    this.coins = 0,
    this.subscriptionTier = 'free',
    this.isSubscribed = false,
    this.activeJobLimit = 3,
    this.proposalLimit = 10,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get name => fullName; // Geriye dönük uyumluluk için

  factory AuthUser.fromMap(Map<String, dynamic> map, {bool emailVerified = false}) {
    final rawName = (map['name'] ?? '').toString().trim();
    final nameParts = rawName.split(' ');

    final roleStr = (map['role'] ?? '').toString().trim().toLowerCase();

    return AuthUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: nameParts.isNotEmpty ? nameParts.first : '',
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      role: UserRole.values.firstWhere(
            (e) => e.name.toLowerCase() == roleStr,
        orElse: () => UserRole.freelancer,
      ),
      emailVerified: emailVerified || (map['email_verified'] ?? false),
      avatar: map['avatar'],
      title: map['title'],
      companyName: map['company_name'],
      industry: map['industry'],
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble(),
      coins: map['coins'] ?? 0,
      subscriptionTier: map['subscription_tier'] ?? 'free',
      isSubscribed: map['is_subscribed'] ?? false,
      activeJobLimit: map['active_job_limit'] ?? 3,
      proposalLimit: map['proposal_limit'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': fullName,
      'role': role.name,
      'title': title,
      'company_name': companyName,
      'industry': industry,
      'hourly_rate': hourlyRate,
      'coins': coins,
      'subscription_tier': subscriptionTier,
      'is_subscribed': isSubscribed,
      'active_job_limit': activeJobLimit,
      'proposal_limit': proposalLimit,
    };
  }
}