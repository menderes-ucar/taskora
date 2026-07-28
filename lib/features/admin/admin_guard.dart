import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/enums/user_role.dart';
import '../auth/presentation/providers/auth_state.dart';

class AdminGuard extends ConsumerWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user != null && (user.role == UserRole.admin || user.role.name == 'admin')) {
      return child;
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gavel_rounded, color: AppColors.danger, size: 48),
              SizedBox(height: 16),
              Text(
                'Yetkisiz Erişim!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Bu alana erişim yetkiniz bulunmamaktadır.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}