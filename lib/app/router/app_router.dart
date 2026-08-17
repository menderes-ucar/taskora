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
import '../../features/admin/admin_guard.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/organization/presentation/pages/organization_page.dart';

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

      case RouteNames.organization:
        return MaterialPageRoute(builder: (_) => const OrganizationPage());

    // Admin Rotaları
      case RouteNames.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminDashboardPage()));

      case RouteNames.adminJobs:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminJobApprovalPage()));

      case RouteNames.adminReports:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminReportsPage()));
      case RouteNames.adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminUsersPage()));
      case RouteNames.adminCoins:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminCoinsPage()));
      case RouteNames.adminPayouts:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminPayoutsPage()));
      case RouteNames.adminCategories:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminCategoriesPage()));
      case RouteNames.adminAnnouncements:
        return MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminAnnouncementsPage()));

      case RouteNames.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Rota bulunamadı: ${settings.name}')),
          ),
        );
    }
  }
}