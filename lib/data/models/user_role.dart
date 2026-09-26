enum UserRole { customer, farmer, admin, superAdmin }

UserRole userRoleFromStorage(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'super_admin':
    case 'superadmin':
    case 'super-admin':
      return UserRole.superAdmin;
    case 'admin':
    case 'administrator':
      return UserRole.admin;
    case 'farmer':
      return UserRole.farmer;
    default:
      return UserRole.customer;
  }
}

String userRoleToStorage(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return 'super_admin';
    case UserRole.admin:
      return 'admin';
    case UserRole.farmer:
      return 'farmer';
    case UserRole.customer:
      return 'customer';
  }
}
