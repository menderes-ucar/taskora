import 'package:flutter/material.dart';
import '../../features/admin/announcements/ui/pages/admin_announcements_page.dart';
import '../../features/admin/categories/ui/pages/admin_categories_page.dart';
import '../../features/admin/coins/ui/pages/admin_coins_page.dart';
import '../../features/admin/payouts/ui/pages/admin_payouts_page.dart';
import '../../features/admin/users/ui/pages/admin_users_page.dart';
import 'route_names.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

import '../../features/employer/ui/pages/employer_main_shell.dart';
import '../../features/freelancer/ui/pages/freelancer_main_shell.dart';

import '../../features/admin/dashboard/ui/pages/admin_dashboard_page.dart';
import '../../features/admin/jobs/ui/pages/admin_job_approval_page.dart';
import '../../features/admin/reports/ui/pages/admin_reports_page.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case RouteNames.employerShell:
        return MaterialPageRoute(builder: (_) => const EmployerMainShell());

      case RouteNames.freelancerShell:
        return MaterialPageRoute(builder: (_) => const FreelancerMainShell());

    // Admin Rotaları
      case RouteNames.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());

      case RouteNames.adminJobs:
        return MaterialPageRoute(builder: (_) => const AdminJobApprovalPage());

      case RouteNames.adminReports:
        return MaterialPageRoute(builder: (_) => const AdminReportsPage());
      case RouteNames.adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersPage());
      case RouteNames.adminCoins:
        return MaterialPageRoute(builder: (_) => const AdminCoinsPage());
      case RouteNames.adminPayouts:
        return MaterialPageRoute(builder: (_) => const AdminPayoutsPage());
      case RouteNames.adminCategories:
        return MaterialPageRoute(builder: (_) => const AdminCategoriesPage());
      case RouteNames.adminAnnouncements:
        return MaterialPageRoute(builder: (_) => const AdminAnnouncementsPage());

      case RouteNames.roleSelection:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Rol Seçim Ekranı')),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Rota bulunamadı: ${settings.name}')),
          ),
        );
    }
  }
}