class OrganizationInvitationModel {
  final String id;
  final String email;
  final String role;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const OrganizationInvitationModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory OrganizationInvitationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationInvitationModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'pending',
      expiresAt: DateTime.tryParse(map['expires_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
