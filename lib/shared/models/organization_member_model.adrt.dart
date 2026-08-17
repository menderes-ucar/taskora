class OrganizationMemberModel {
  final String userId;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final String name;
  final String email;
  final String? avatarUrl;

  const OrganizationMemberModel({
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory OrganizationMemberModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map
        ? Map<String, dynamic>.from(map['profiles'] as Map)
        : <String, dynamic>{};

    return OrganizationMemberModel(
      userId: map['user_id']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'active',
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? ''),
      name: profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString().trim()
          : 'Kullanıcı',
      email: profile['email']?.toString() ?? '',
      avatarUrl: profile['avatar_url']?.toString(),
    );
  }
}
