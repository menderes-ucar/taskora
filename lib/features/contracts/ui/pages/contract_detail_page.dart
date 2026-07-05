import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/enums/job_status.dart';
import '../../../../shared/enums/payment_status.dart';
import '../../../../shared/enums/transaction_type.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../freelancer/jobs/ui/logic/jobs_provider.dart';
import '../../../wallet/logic/transactions_provider.dart';
import '../../../wallet/logic/wallet_provider.dart';
import '../../logic/contracts_provider.dart';

class ContractDetailPage extends ConsumerWidget {
  final String contractId;

  const ContractDetailPage({
    super.key,
    required this.contractId,
  });

  Color _paymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.funded:
        return AppColors.primaryDark;
      case PaymentStatus.released:
        return AppColors.success;
      case PaymentStatus.refunded:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final contractsAsync = ref.watch(contractsProvider);
    final walletAsync = ref.watch(walletProvider);

    return contractsAsync.when(
      data: (_) {
        final contract = ref.read(contractsProvider.notifier).getById(contractId);

        if (contract == null) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: const Center(
              child: Text('Proje bulunamadı'),
            ),
          );
        }

        final isFreelancer = currentUser?.id == contract.freelancerId;
        final isEmployer = currentUser?.id == contract.employerId;
        final paymentColor = _paymentColor(contract.paymentStatus);

        return walletAsync.when(
          data: (wallet) {
            return Scaffold(
              backgroundColor: AppColors.primary,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                scrolledUnderElevation: 0,
                title: const Text('Proje Detayı'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionCard(
                    title: 'Proje Bilgileri',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.jobTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppChip(label: contract.status.label),
                            AppChip(label: '${contract.deliveryDays} gün'),
                            AppChip(
                              label: contract.paymentStatus.label,
                              color: paymentColor.withValues(alpha: 0.12),
                              textColor: paymentColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _DetailRow(
                          title: 'Freelancer',
                          value: contract.freelancerName,
                        ),
                        _DetailRow(
                          title: 'Anlaşma Tutarı',
                          value: '₺${contract.agreedAmount.toStringAsFixed(0)}',
                        ),
                        _DetailRow(
                          title: 'Durum',
                          value: contract.status.label,
                        ),
                        _DetailRow(
                          title: 'Ödeme',
                          value: contract.paymentStatus.label,
                        ),
                        if (isEmployer)
                          _DetailRow(
                            title: 'Cüzdan Bakiyesi',
                            value: '₺${wallet.balance.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Proje Akışı',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TimelineItem(
                          title: 'Proje Başladı',
                          subtitle:
                          'Teklif kabul edildi ve proje aktif hale geldi.',
                          isDone: true,
                        ),
                        _TimelineItem(
                          title: 'Ödeme Güvenceye Alındı',
                          subtitle:
                          'İşveren ödeme güvence adımını tamamlayacak.',
                          isDone:
                          contract.paymentStatus == PaymentStatus.funded ||
                              contract.paymentStatus ==
                                  PaymentStatus.released,
                        ),
                        _TimelineItem(
                          title: 'Teslim Bekleniyor',
                          subtitle: 'Freelancer projeyi teslim edecek.',
                          isDone:
                          contract.status == ContractStatus.delivered ||
                              contract.status == ContractStatus.completed,
                        ),
                        _TimelineItem(
                          title: 'Tamamlandı',
                          subtitle:
                          'İşveren projeyi tamamlandı olarak işaretleyecek.',
                          isDone: contract.status == ContractStatus.completed,
                        ),
                        _TimelineItem(
                          title: 'Ödeme Serbest Bırakıldı',
                          subtitle:
                          'Tamamlanan proje için ödeme freelancera aktarılır.',
                          isDone:
                          contract.paymentStatus == PaymentStatus.released,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isEmployer &&
                      contract.paymentStatus == PaymentStatus.pending)
                    PrimaryButton(
                      text: 'Ödemeyi Güvenceye Al',
                      icon: Icons.lock_outline_rounded,
                      onPressed: () async {
                        if (wallet.balance < contract.agreedAmount) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cüzdanda yeterli bakiye yok',
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        await ref
                            .read(walletProvider.notifier)
                            .withdraw(contract.agreedAmount);

                        await ref
                            .read(transactionsProvider.notifier)
                            .addTransaction(
                          amount: contract.agreedAmount,
                          type: TransactionType.escrowFunding,
                          title: 'Escrow Ödemesi',
                          description:
                          '${contract.jobTitle} işi için ödeme güvenceye alındı.',
                          isIncome: false,
                        );

                        await ref
                            .read(contractsProvider.notifier)
                            .fundContract(contract.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ödeme güvenceye alındı'),
                            ),
                          );
                        }
                      },
                    ),
                  if (isFreelancer &&
                      contract.status == ContractStatus.active &&
                      contract.paymentStatus == PaymentStatus.funded)
                    PrimaryButton(
                      text: 'Projeyi Teslim Et',
                      icon: Icons.upload_file_rounded,
                      onPressed: () async {
                        await ref
                            .read(contractsProvider.notifier)
                            .updateContractStatus(
                          contract.id,
                          ContractStatus.delivered,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Proje teslim edildi olarak işaretlendi',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  if (isEmployer &&
                      contract.status == ContractStatus.delivered)
                    PrimaryButton(
                      text: 'Projeyi Tamamla',
                      icon: Icons.task_alt_rounded,
                      onPressed: () async {
                        await ref
                            .read(contractsProvider.notifier)
                            .updateContractStatus(
                          contract.id,
                          ContractStatus.completed,
                        );

                        await ref.read(jobsProvider.notifier).updateJobStatus(
                          contract.jobId,
                          JobStatus.completed,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proje tamamlandı'),
                            ),
                          );
                        }
                      },
                    ),
                  if (isEmployer &&
                      contract.status == ContractStatus.completed &&
                      contract.paymentStatus == PaymentStatus.funded)
                    PrimaryButton(
                      text: 'Ödemeyi Serbest Bırak',
                      icon: Icons.payments_rounded,
                      onPressed: () async {
                        await ref
                            .read(contractsProvider.notifier)
                            .releasePayment(contract.id);

                        await ref
                            .read(transactionsProvider.notifier)
                            .addTransaction(
                          amount: contract.agreedAmount,
                          type: TransactionType.paymentRelease,
                          title: 'Ödeme Serbest Bırakıldı',
                          description:
                          '${contract.jobTitle} işi için ödeme serbest bırakıldı.',
                          isIncome: false,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ödeme freelancera serbest bırakıldı',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  if (isEmployer && contract.status == ContractStatus.active)
                    const Text(
                      'Ödemeyi güvenceye aldıktan sonra freelancer teslim sürecine geçebilir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.grey,
                        height: 1.5,
                      ),
                    ),
                  if (isFreelancer &&
                      contract.paymentStatus == PaymentStatus.pending)
                    const Text(
                      'İşveren ödemeyi güvenceye aldıktan sonra teslim sürecine geçebilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.grey,
                        height: 1.5,
                      ),
                    ),
                  if (contract.status == ContractStatus.completed &&
                      contract.paymentStatus == PaymentStatus.released)
                    const Text(
                      'Bu proje ve ödeme süreci tamamlandı.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            backgroundColor: AppColors.primary,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: const Text('Proje Detayı'),
            ),
            body: Center(
              child: Text('Hata: $error'),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Proje Detayı'),
        ),
        body: Center(
          child: Text('Hata: $error'),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.success : AppColors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: isDone
                  ? const Icon(
                Icons.check,
                size: 10,
                color: AppColors.success,
              )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDone ? AppColors.black : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}