import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

import '../../../../app/config/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../wallet/providers/wallet_provider.dart';
import '../../../notification/presentation/pages/notification_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _showLanguageBottomSheet(BuildContext context) {
    final currentLocale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'tr';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 16),
                  child: Text('Dil Seçimi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black)),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  leading: const Text('🇹🇷', style: TextStyle(fontSize: 22)),
                  title: const Text('Türkçe', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.black)),
                  trailing: currentLocale == 'tr' ? const Icon(Icons.check_circle, color: AppColors.primaryDark) : null,
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                  title: const Text('English', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.black)),
                  trailing: currentLocale == 'en' ? const Icon(Icons.check_circle, color: AppColors.primaryDark) : null,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentLocaleStr = Localizations.maybeLocaleOf(context)?.languageCode == 'en' ? 'English' : 'Türkçe';

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppConstants.translate(context, 'settings'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildSectionTitle('HESAP HAREKETLERİ'),
          _SettingsTile(icon: Icons.dark_mode_outlined, title: 'Tema', subtitle: 'Sistem Teması aktif', onTap: () {}),
          _SettingsTile(icon: Icons.language_rounded, title: 'Uygulama Dili', subtitle: currentLocaleStr, onTap: () => _showLanguageBottomSheet(context)),
          _SettingsTile(
            icon: Icons.star_purple500_rounded,
            title: 'Üyelik Planı',
            subtitle: authState.user?.subscriptionTier == 'premium' ? 'Premium Üye (Sınırsız Paket)' : 'Ücretsiz Plan (Limitleri Yükselt)',
            isPremium: true,
            onTap: () async {
              if (authState.user?.subscriptionTier == 'premium') return;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Text('Premium Pakete Geçin 🚀', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w900)),
                  content: const Text('Aylık sadece ₺150 karşılığında Premium pakete geçerek limitlerinizi yükseltin.', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.w500)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold))),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Satın Al', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(walletProvider.notifier).upgradeToPremium();
              }
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: AppConstants.translate(context, 'logout'),
            icon: Icons.logout_rounded,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Hesabı Kalıcı Olarak Sil', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Text('Emin misiniz?', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900)),
                  content: const Text('Bu işlem geri alınamaz. Tüm ilan ve cüzdan verileriniz silinecektir.', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.w500)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal Et', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold))),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet, Sil', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
              if (confirmDelete == true) {
                await ref.read(authProvider.notifier).deleteAccount();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap; final bool isPremium;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isPremium ? AppColors.warning : AppColors.primaryDark).withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: onTap,
        leading: Icon(icon, color: isPremium ? AppColors.warning : AppColors.primaryDark),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.black,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark, size: 18),
      ),
    );
  }
}