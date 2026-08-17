enum UserRole {
  freelancer,
  employer,
  admin,
  superAdmin,
}

extension UserRoleX on UserRole {
  bool get isAdminRole => this == UserRole.admin || this == UserRole.superAdmin;

  bool get isSelfAssignable => this == UserRole.freelancer || this == UserRole.employer;
}
