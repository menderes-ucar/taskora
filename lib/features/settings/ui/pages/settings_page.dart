import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';


class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tema',
            subtitle: 'Yakında eklenecek',
          ),
          const SizedBox(height: 12),
          const _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Bildirimler',
            subtitle: 'Yakında eklenecek',
          ),
          const SizedBox(height: 12),
          const _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Dil',
            subtitle: 'Yakında eklenecek',
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Çıkış Yap',
            icon: Icons.logout_rounded,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Çıkış yapılsın mı?'),
                  content: const Text(
                    'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                ref.read(authProvider.notifier).logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                      (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryDark,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.grey,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.grey,
        ),
      ),
    );
  }
}