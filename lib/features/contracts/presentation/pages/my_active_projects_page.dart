import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../logic/contracts_provider.dart';
import 'contract_detail_page.dart';

class MyActiveProjectsPage extends ConsumerWidget {
  const MyActiveProjectsPage({super.key});

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
              'İşveren Paneli',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Escrow havuzundaki fonlar ve aktif projeler',
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
              if (c.employerId != currentUser.id) return false;
              final statusName = c.status.name.toLowerCase();
              return statusName != 'completed' &&
                  statusName != 'cancelled' &&
                  statusName != 'disputed';
            }).toList();

            final totalEscrow = myContracts.fold<double>(
              0,
                  (sum, item) => sum + item.agreedAmount,
            );

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 🚀 HERO ESCROW BAKIYE KARTI
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Kilitli Escrow Bakiyesi',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '₺${totalEscrow.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ödemeler iş onayınızın ardından freelancer hesaplarına aktarılır.',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Yürütülen Projeler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${myContracts.length} Aktif',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (myContracts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'Aktif yürütülen bir projeniz bulunmuyor.',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ...myContracts.map((contract) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      title: Text(
                        contract.jobTitle,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                contract.freelancerName.isNotEmpty
                                    ? contract.freelancerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              contract.freelancerName,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₺${contract.agreedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getContractStatusText(contract.status),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContractDetailPage(
                            contractId: contract.id,
                          ),
                        ),
                      ),
                    ),
                  )),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (err, _) => Center(
            child: Text('Hata: $err', style: const TextStyle(color: Colors.white)),
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
}