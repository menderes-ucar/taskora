import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';
import '../../../../shared/enums/user_role.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await ref.read(authProvider.notifier).signIn(
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage ?? 'Giriş başarısız'),
        ),
      );
      return;
    }

    final role = authState.user?.role;

    if (role == UserRole.employer) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.employerShell,
            (_) => false,
      );
      return;
    }

    if (role == UserRole.freelancer) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.freelancerShell,
            (_) => false,
      );
      return;
    }

    Navigator.pushNamed(context, RouteNames.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Taskora',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Freelancer ve işverenleri buluşturan platform',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'E-posta',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Şifre',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                child: authState.isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Giriş Yap'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Kayıt Ol',
                  style: TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}