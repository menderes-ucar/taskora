import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskora/shared/enums/contract_status.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../shared/models/contract_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../contracts/logic/contracts_provider.dart';
import '../../../../contracts/ui/pages/contract_detail_page.dart';

class MyActiveJobsPage extends ConsumerWidget {
  const MyActiveJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final contractsAsync = ref.watch(contractsProvider);

    return contractsAsync.when(
      data: (contracts) {
        final myContracts = currentUser == null
            ? <ContractModel>[]
            : contracts
            .where(
              (c) =>
          c.freelancerId == currentUser.id &&
              (c.status == ContractStatus.active ||
                  c.status == ContractStatus.delivered),
        )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Aktif İşlerim'),
          ),
          body: myContracts.isEmpty
              ? const EmptyState(
            icon: Icons.work_outline,
            title: 'Aktif iş yok',
            subtitle: 'Kabul edilen işler burada görünecek.',
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: myContracts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final contract = myContracts[index];

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ContractDetailPage(contractId: contract.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.jobTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AppChip(label: contract.status.label),
                          const SizedBox(width: 8),
                          AppChip(label: '${contract.deliveryDays} gün'),
                          const Spacer(),
                          Text(
                            '₺${contract.agreedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Aktif İşlerim'),
        ),
        body: Center(
          child: Text('Hata: $error'),
        ),
      ),
    );
  }
}