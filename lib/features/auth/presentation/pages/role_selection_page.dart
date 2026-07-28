import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../notification/data/services/notification_helper.dart'; // 🚀 EKLENDİ
import '../providers/auth_state.dart';

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  Future<void> _selectRole(
      BuildContext context, WidgetRef ref, UserRole role) async {
    final success = await ref.read(authProvider.notifier).updateRole(role);

    if (!context.mounted) return;

    final authState = ref.read(authProvider);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            authState.errorMessage ?? 'Rol güncellenemedi',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    // 🚀 ROL BAŞARIYLA SEÇİLDİĞİNDE FCM TOKEN'I VERİTABANINA YAZ
    await NotificationHelper.saveFcmToken();

    if (role == UserRole.freelancer) {
      Navigator.pushNamedAndRemoveUntil(
          context, RouteNames.freelancerShell, (_) => false);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
        context, RouteNames.employerShell, (_) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Rol Seçimi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Nasıl devam etmek istiyorsun?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Freelancer olarak iş bulabilir veya işveren olarak ilan yayınlayabilirsin.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            _RoleCard(
              title: 'Freelancer',
              subtitle: 'İlanları incele, teklif ver, projeleri yönet',
              icon: Icons.work_outline_rounded,
              onTap: authState.isLoading
                  ? null
                  : () => _selectRole(context, ref, UserRole.freelancer),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              title: 'İşveren',
              subtitle: 'İş ilanı oluştur, teklifleri incele, freelancer seç',
              icon: Icons.business_center_outlined,
              onTap: authState.isLoading
                  ? null
                  : () => _selectRole(context, ref, UserRole.employer),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: AppColors.primaryDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}