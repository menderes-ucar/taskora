import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../logic/contracts_provider.dart';
import 'contract_detail_page.dart';

class MyActiveJobsPage extends ConsumerWidget {
  const MyActiveJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final contractsAsync = ref.watch(contractsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary, // 🚀 TURKUAZ ARKA PLAN
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context), // 🚀 GERİ BUTONU
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktif İşlerim',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Devam eden sözleşmeleriniz ve teslimat durumları',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await ref.read(contractsProvider.notifier).refreshContracts();
        },
        child: contractsAsync.when(
          data: (contracts) {
            final myContracts = currentUser == null
                ? <ContractModel>[]
                : contracts.where((c) {
              if (c.freelancerId != currentUser.id) return false;
              final statusName = c.status.name.toLowerCase();
              return statusName != 'completed' &&
                  statusName != 'cancelled' &&
                  statusName != 'disputed';
            }).toList();

            if (myContracts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.work_outline_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aktif Sözleşmeniz Bulunmuyor',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kabul edilen teklifleriniz burada listelenir.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: myContracts.length,
              itemBuilder: (context, index) {
                final contract = myContracts[index];
                return _buildJobCard(context, contract);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, _) => Center(
            child: Text('Yükleme Hatası: $error', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, ContractModel contract) {
    final statusBadge = _getStatusBadgeConfig(contract.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContractDetailPage(contractId: contract.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBadge.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusBadge.textColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getContractStatusText(contract.status),
                            style: TextStyle(
                              color: statusBadge.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${contract.agreedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  contract.jobTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        'Teslimat Süresi: ${contract.deliveryDays} Gün',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primaryDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getContractStatusText(ContractStatus status) {
    switch (status) {
      case ContractStatus.waitingPayment:
        return 'Ödeme Bekleniyor';
      case ContractStatus.funded:
        return 'Ödeme Havuzda';
      case ContractStatus.active:
        return 'Devam Ediyor';
      case ContractStatus.submitted:
        return 'Teslim Edildi';
      case ContractStatus.revisionRequested:
        return 'Revizyon İstendi';
      case ContractStatus.completed:
        return 'Tamamlandı';
      case ContractStatus.disputed:
        return 'Uyuşmazlık Açıldı';
      case ContractStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  _BadgeConfig _getStatusBadgeConfig(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
      case ContractStatus.funded:
        return _BadgeConfig(const Color(0xFFEFF6FF), const Color(0xFF2563EB));
      case ContractStatus.submitted:
        return _BadgeConfig(const Color(0xFFFEF3C7), const Color(0xFFD97706));
      case ContractStatus.revisionRequested:
        return _BadgeConfig(const Color(0xFFFEE2E2), const Color(0xDC2626));
      default:
        return _BadgeConfig(const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }
}

class _BadgeConfig {
  final Color bgColor;
  final Color textColor;

  _BadgeConfig(this.bgColor, this.textColor);
}