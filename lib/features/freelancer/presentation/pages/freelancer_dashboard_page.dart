// lib/features/freelancer/presentation/pages/freelancer_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider; // Supabase'deki Provider ismini gizleyerek çakışmayı çözdük

import '../../../../app/theme/app_colors.dart'; // Önceki sayfada kullandığımız ana tema renk dosyan
import '../../../../core/services/contract_service.dart';
import '../../../../core/services/wallet_services.dart';

final activeContractsProvider = FutureProvider.family<dynamic, String>((ref, userId) async {
  final contractService = ref.read(contractServiceProvider);
  return contractService.getActiveContracts(userId);
});

final walletProvider = FutureProvider.family<dynamic, String>((ref, userId) async {
  final walletService = ref.read(walletServiceProvider);
  return walletService.getWallet(userId);
});

// Riverpod Provider kullanımı çakışma giderildiği için artık güvenli
final contractServiceProvider = Provider<IContractService>((ref) {
  return SupabaseContractService(ref.read(supabaseClientProvider));
});

final walletServiceProvider = Provider<IWalletService>((ref) {
  return SupabaseWalletService(ref.read(supabaseClientProvider));
});

final supabaseClientProvider = Provider((ref) {
  return Supabase.instance.client;
});

class FreelancerDashboardPage extends ConsumerWidget {
  final String userId;

  const FreelancerDashboardPage({
    super.key, // Güncel key kullanımı
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Arka plan rengi projenin ana rengine çekildi
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWalletCard(ref, userId),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 20),
          _buildActiveContractsSection(ref, userId),
          const SizedBox(height: 16),
          _buildQuickActionsRow(context),
        ],
      ),
    );
  }

  Widget _buildWalletCard(WidgetRef ref, String userId) {
    final walletAsync = ref.watch(walletProvider(userId));

    return walletAsync.when(
      data: (wallet) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Kullanılabilir Bakiye',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 12),
              Text(
                  '₺${wallet['balance']?.toString() ?? '0.00'}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)
              ),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Colors.white))),
      error: (e, st) => const SizedBox(height: 150),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Aktif İşler', '3', AppColors.primaryDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Tamamlanan', '12', AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Puanlama', '4.8★', Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)
            ),
            const SizedBox(height: 6),
            Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.grey, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContractsSection(WidgetRef ref, String userId) {
    final contractsAsync = ref.watch(activeContractsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
              'Aktif Sözleşmeler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.white)
          ),
        ),
        const SizedBox(height: 12),
        contractsAsync.when(
          data: (contracts) {
            final list = contracts is List ? contracts : [];
            if (list.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Aktif sözleşme bulunamadı', style: TextStyle(color: Colors.white70)),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) => _buildContractCard(list[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, st) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildContractCard(dynamic contract) {
    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          contract['job_title'] ?? 'İş Başlığı',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.black),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '₺${contract['agreed_amount'] ?? '0'} • ${contract['delivery_days'] ?? 0} Gün',
            style: const TextStyle(color: AppColors.grey, fontWeight: FontWeight.w500),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            contract['status'] ?? 'aktif',
            style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.of(context).pushNamed('/jobs'),
            icon: const Icon(Icons.work_outline_rounded),
            label: const Text('İşlere Göz At', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.of(context).pushNamed('/messages'),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Mesajlar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}