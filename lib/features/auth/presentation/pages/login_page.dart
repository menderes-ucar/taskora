import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../notification/data/services/notification_helper.dart'; // 🚀 EKLENDİ
import '../providers/auth_state.dart';
import 'register_page.dart';

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
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            authState.errorMessage ?? AppConstants.translate(context, 'error_occurred'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }

    // 🚀 GİRİŞ BAŞARILI OLDUĞUNDA FCM TOKEN'I VERİTABANINA YAZ
    await NotificationHelper.saveFcmToken();

    // AuthGate observes authProvider and selects the role surface.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Taskora',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.translate(context, 'welcome_subtitle'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                TextField(
                  controller: emailController,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: AppConstants.translate(context, 'email'),
                    hintStyle: const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.primaryDark),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.primaryDark.withValues(alpha: 0.20),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.primaryDark.withValues(alpha: 0.20),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primaryDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: AppConstants.translate(context, 'password'),
                    hintStyle: const TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.lock_open_rounded, color: AppColors.primaryDark),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.primaryDark.withValues(alpha: 0.20),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.primaryDark.withValues(alpha: 0.20),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primaryDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text(
                      AppConstants.translate(context, 'login'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      AppConstants.translate(context, 'register'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}