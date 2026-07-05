import '../../../../shared/enums/user_role.dart';

class AuthUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final UserRole role;
  final bool emailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.emailVerified,
    this.avatar,
  });

  String get fullName => "$firstName $lastName";
}