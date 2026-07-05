import 'package:flutter/material.dart';


import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/employer/ui/pages/employer_main_shell.dart';

import '../../features/freelancer/ui/pages/freelancer_main_shell.dart';
import 'route_names.dart';

class AppRouter {
  static const login = RouteNames.login;
  static const roleSelection = RouteNames.roleSelection;
  static const freelancerShell = RouteNames.freelancerShell;
  static const employerShell = RouteNames.employerShell;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case RouteNames.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionPage());

      case RouteNames.freelancerShell:
        return MaterialPageRoute(builder: (_) => const FreelancerMainShell());

      case RouteNames.employerShell:
        return MaterialPageRoute(builder: (_) => const EmployerMainShell());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Sayfa bulunamadı')),
          ),
        );
    }
  }
}