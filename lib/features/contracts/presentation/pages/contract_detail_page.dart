import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_delivery_model.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../../shared/models/contract_timeline_model.dart';
import '../../logic/contracts_provider.dart';

class ContractDetailPage extends ConsumerStatefulWidget {
  final String contractId;

  const ContractDetailPage({super.key, required this.contractId});

  @override
  ConsumerState<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends ConsumerState<ContractDetailPage> {
  late Future<List<ContractDeliveryModel>> _deliveriesFuture;
  late Future<List<ContractTimelineModel>> _timelineFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final notifier = ref.read(contractsProvider.notifier);
    _deliveriesFuture = notifier.getDeliveries(widget.contractId);
    _timelineFuture = notifier.getTimeline(widget.contractId);
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(contractsProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Proje Yönetim Paneli',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: contractsAsync.when(
        data: (contracts) {
          final contract = contracts.firstWhere(
                (c) => c.id == widget.contractId,
            orElse: () => throw Exception('Kontrat bulunamadı'),
          );

          final bool isFreelancer = contract.freelancerId == currentUserId;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeroCard(contract),
                    const SizedBox(height: 20),
                    _buildStepper(contract.status),
                    const SizedBox(height: 20),
                    _buildEscrowBadge(contract),
                    const SizedBox(height: 28),
                    const Text(
                      'Teslim Edilen Sürümler (Deliveries)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<ContractDeliveryModel>>(
                      future: _deliveriesFuture,
                      builder: (context, snapshot) {
                        final deliveries = snapshot.data ?? [];
                        if (deliveries.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Henüz herhangi bir teslimat yapılmadı.',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: deliveries.map((d) => _buildDeliveryCard(d)).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'İşlem Geçmişi & Audit Log',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<ContractTimelineModel>>(
                      future: _timelineFuture,
                      builder: (context, snapshot) {
                        final timeline = snapshot.data ?? [];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: timeline.asMap().entries.map((entry) {
                              final isLast = entry.key == timeline.length - 1;
                              return _buildTimelineItem(entry.value, isLast);
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildStickyActionBar(contract, isFreelancer),
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
    );
  }

  Widget _buildHeroCard(ContractModel contract) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₺${contract.agreedAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  contract.status.label,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contract.jobTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(ContractStatus status) {
    final steps = ['Teklif', 'Ödeme', 'Çalışılıyor', 'Teslim', 'Onay'];

    int currentStep = 0;
    if (status == ContractStatus.waitingPayment) currentStep = 0;
    if (status == ContractStatus.funded || status == ContractStatus.active) currentStep = 2;
    if (status == ContractStatus.submitted || status == ContractStatus.revisionRequested) currentStep = 3;
    if (status == ContractStatus.completed) currentStep = 4;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isDone = index <= currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : (isDone ? AppColors.primaryDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: isDone ? AppColors.primaryDark : const Color(0xFFE2E8F0),
                      child: isDone
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == steps.length - 1
                            ? Colors.transparent
                            : (index < currentStep ? AppColors.primaryDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                    color: isDone ? AppColors.primaryDark : AppColors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEscrowBadge(ContractModel contract) {
    final bool isFunded = contract.status != ContractStatus.waitingPayment;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFunded ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFunded ? const Color(0xFFDCFCE7) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFunded ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
            color: isFunded ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isFunded
                  ? '₺${contract.agreedAmount.toStringAsFixed(0)} tutarındaki bakiye platform Escrow havuzunda korumadadır.'
                  : 'Sözleşme başlatıldı. İşverenin ₺${contract.agreedAmount.toStringAsFixed(0)} tutarındaki Escrow bakiyesini yatırması bekleniyor.',
              style: TextStyle(
                color: isFunded ? const Color(0xFF15803D) : const Color(0xFFB45309),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(ContractDeliveryModel delivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Sürüm v${delivery.version}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '${delivery.createdAt.day}.${delivery.createdAt.month}.${delivery.createdAt.year}',
                style: const TextStyle(color: AppColors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            delivery.message,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (delivery.fileUrl != null && delivery.fileUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(delivery.fileUrl!);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        delivery.fileUrl!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ContractTimelineModel item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1, color: const Color(0xFFE2E8F0)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.black,
                    ),
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActionBar(ContractModel contract, bool isFreelancer) {
    if (contract.status == ContractStatus.completed ||
        contract.status == ContractStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: isFreelancer
            ? _buildFreelancerBottomBar(contract)
            : _buildEmployerBottomBar(contract),
      ),
    );
  }

  Widget _buildFreelancerBottomBar(ContractModel contract) {
    if (contract.status == ContractStatus.waitingPayment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 18),
            SizedBox(width: 8),
            Text(
              'İşverenin Escrow Ödemesi Yapması Bekleniyor...',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => _showSubmitModal(contract.id),
        child: const Text('Yeni Versiyon Teslim Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmployerBottomBar(ContractModel contract) {
    if (contract.status == ContractStatus.waitingPayment) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
          label: Text(
            '₺${contract.agreedAmount.toStringAsFixed(0)} Escrow Bakiyesini Yatır',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onPressed: () async {
            await ref.read(contractsProvider.notifier).updateContractStatus(
              contract.id,
              ContractStatus.funded,
            );
            setState(() => _loadData());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('Escrow ödemesi başarıyla havuza alındı! Freelancer çalışmaya başlayabilir.'),
                ),
              );
            }
          },
        ),
      );
    }

    if (contract.status == ContractStatus.submitted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showRevisionModal(contract.id),
              child: const Text('Revizyon İste', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await ref.read(contractsProvider.notifier).approveAndReleasePayment(contract.id);
                setState(() => _loadData());
              },
              child: const Text('Onayla & Öde', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showSubmitModal(String contractId) {
    final messageCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yeni Versiyon Teslim Et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.black)),
            const SizedBox(height: 14),
            TextField(controller: messageCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Teslimat notu...', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: linkCtrl, decoration: const InputDecoration(hintText: 'Drive / Figma / GitHub Linki', border: OutlineInputBorder())),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                onPressed: () async {
                  if (messageCtrl.text.trim().isEmpty) return;
                  await ref.read(contractsProvider.notifier).submitDelivery(contractId: contractId, message: messageCtrl.text.trim(), fileUrl: linkCtrl.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() => _loadData());
                  }
                },
                child: const Text('Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showRevisionModal(String contractId) {
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revizyon Talebi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.black)),
            const SizedBox(height: 14),
            TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Düzeltilmesini istediğiniz detaylar', border: OutlineInputBorder())),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xD97706)),
                onPressed: () async {
                  if (reasonCtrl.text.trim().isEmpty) return;
                  await ref.read(contractsProvider.notifier).requestRevision(contractId: contractId, reason: reasonCtrl.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() => _loadData());
                  }
                },
                child: const Text('Talebi İlet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}