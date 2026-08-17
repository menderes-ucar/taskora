import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../admin/dashboard/ui/pages/admin_dashboard_page.dart';
import '../../../employer/ui/pages/employer_main_shell.dart';
import '../../../freelancer/ui/pages/freelancer_main_shell.dart';
import '../pages/login_page.dart';
import '../providers/auth_provider.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    if (state.isLoading) return const _AuthLoadingView();
    if (!state.isLoggedIn || state.user == null) return const LoginPage();
    switch (state.user!.role) {
      case UserRole.admin:
      case UserRole.superAdmin:
        return const AdminDashboardPage();
      case UserRole.employer:
        return const EmployerMainShell();
      case UserRole.freelancer:
        return const FreelancerMainShell();
    }
  }
}

class AuthRouteGuard extends ConsumerWidget {
  final Widget child;
  final Set<UserRole> allowedRoles;

  const AuthRouteGuard({super.key, required this.child, required this.allowedRoles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    if (state.isLoading) return const _AuthLoadingView();
    final user = state.user;
    if (!state.isLoggedIn || user == null) return const LoginPage();
    if (!allowedRoles.contains(user.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetkisiz Erişim')),
        body: Center(
          child: FilledButton(
            onPressed: () {
              final route = switch (user.role) {
                UserRole.admin => RouteNames.adminDashboard,
                UserRole.superAdmin => RouteNames.adminDashboard,
                UserRole.employer => RouteNames.employerShell,
                UserRole.freelancer => RouteNames.freelancerShell,
              };
              Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
            },
            child: const Text('Panelime Dön'),
          ),
        ),
      );
    }
    return child;
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(child: CircularProgressIndicator(color: Colors.white)),
  );
}
