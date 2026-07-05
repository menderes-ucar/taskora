import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/user_role.dart';
import '../providers/auth_provider.dart';

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  Future<void> _selectRole(
      BuildContext context,
      WidgetRef ref,
      UserRole role,
      ) async {
    final success = await ref.read(authProvider.notifier).updateRole(role);

    if (!context.mounted) return;

    final authState = ref.read(authProvider);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage ?? 'Rol güncellenemedi'),
        ),
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

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.employerShell,
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol Seçimi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Nasıl devam etmek istiyorsun?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Freelancer olarak iş bulabilir veya işveren olarak ilan yayınlayabilirsin.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _RoleCard(
              title: 'Freelancer',
              subtitle: 'İlanları incele, teklif ver, projeleri yönet',
              icon: Icons.work_outline_rounded,
              onTap: authState.isLoading
                  ? null
                  : () => _selectRole(
                context,
                ref,
                UserRole.freelancer,
              ),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              title: 'İşveren',
              subtitle: 'İş ilanı oluştur, teklifleri incele, freelancer seç',
              icon: Icons.business_center_outlined,
              onTap: authState.isLoading
                  ? null
                  : () => _selectRole(
                context,
                ref,
                UserRole.employer,
              ),
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
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            color: AppColors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}