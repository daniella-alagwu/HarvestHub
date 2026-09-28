import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/customer/shell/customer_shell.dart';
import '../screens/farmer/farmer_home_shell.dart';

Widget screenForRole(String role) {
  switch (role) {
    case 'admin':
      return const AdminDashboardScreen();
    case 'farmer':
      return const FarmerHomeShell();
    case 'customer':
      return const CustomerShell();
    default:
      return const RoleSelectionScreen();
  }
}

bool roleNeedsEmailVerification(String role) => role != 'admin';
