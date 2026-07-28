import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../admin_guard.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        content: const Text('Admin panelinden çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text(
            "Yönetim Paneli",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Çıkış Yap',
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () => _handleLogout(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: const [
            _Card(
              title: "İlan Onay",
              icon: Icons.assignment_turned_in_rounded,
              route: RouteNames.adminJobs,
            ),
            _Card(
              title: "Kullanıcı Yönetimi",
              icon: Icons.people_alt_rounded,
              route: RouteNames.adminUsers,
            ),
            _Card(
              title: "Ödeme Talepleri",
              icon: Icons.payments_rounded,
              route: RouteNames.adminPayouts,
            ),
            _Card(
              title: "Bakiye İşlemleri",
              icon: Icons.monetization_on_rounded,
              route: RouteNames.adminCoins,
            ),
            _Card(
              title: "Kategori Yönetimi",
              icon: Icons.category_rounded,
              route: RouteNames.adminCategories,
            ),
            _Card(
              title: "Duyuru Yayınla",
              icon: Icons.campaign_rounded,
              route: RouteNames.adminAnnouncements,
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title, route;
  final IconData icon;

  const _Card({
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, route),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: AppColors.primaryDark),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}