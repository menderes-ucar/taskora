import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../logic/contracts_provider.dart';

class ContractActionBar extends ConsumerWidget {
  final ContractModel contract;
  final bool isFreelancer;
  final VoidCallback onRefresh;

  const ContractActionBar({
    super.key,
    required this.contract,
    required this.isFreelancer,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tamamlanmış veya İptal Edilmiş işlerde aksiyon barı gizle
    if (contract.status == ContractStatus.completed ||
        contract.status == ContractStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isFreelancer ? _buildFreelancerActions(context, ref) : _buildEmployerActions(context, ref),
      ),
    );
  }

  Widget _buildFreelancerActions(BuildContext context, WidgetRef ref) {
    if (contract.status == ContractStatus.active ||
        contract.status == ContractStatus.revisionRequested ||
        contract.status == ContractStatus.funded) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.upload_file_rounded, size: 20),
          label: Text(
            contract.status == ContractStatus.revisionRequested
                ? 'Yeni Versiyon Teslim Et (Revizyon)'
                : 'Proje Teslimatı Yap (Yeni Versiyon)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showSubmitDeliveryModal(context, ref),
        ),
      );
    }

    if (contract.status == ContractStatus.submitted) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            SizedBox(width: 10),
            Text(
              'Teslimat İncelemede. İşveren Onayı Bekleniyor...',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmployerActions(BuildContext context, WidgetRef ref) {
    if (contract.status == ContractStatus.submitted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(color: Colors.amber.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showRevisionModal(context, ref),
              child: Text(
                'Revizyon İste',
                style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await ref.read(contractsProvider.notifier).approveAndReleasePayment(contract.id);
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Proje onaylandı & Escrow ödemesi serbest bırakıldı! 🎉'),
                    ),
                  );
                }
              },
              child: const Text('Onayla & Öde', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showSubmitDeliveryModal(BuildContext context, WidgetRef ref) {
    final messageController = TextEditingController();
    final linkController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni Versiyon Teslim Et',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dosyalarınızı Google Drive, Figma, GitHub veya Wetransfer linki olarak ekleyebilirsiniz.',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Teslimat notu / Yapılan çalışmalar...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkController,
              decoration: InputDecoration(
                hintText: 'Proje Linki / GitHub / Drive (Opsiyonel)',
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primaryDark),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (messageController.text.trim().isEmpty) return;

                  await ref.read(contractsProvider.notifier).submitDelivery(
                    contractId: contract.id,
                    message: messageController.text.trim(),
                    fileUrl: linkController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    onRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Teslimat başarıyla yapıldı!'),
                      ),
                    );
                  }
                },
                child: const Text('Teslimatı Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevisionModal(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revizyon Talebi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nelerin düzeltilmesini istiyorsunuz? Detaylı açıklayın...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) return;

                  await ref.read(contractsProvider.notifier).requestRevision(
                    contractId: contract.id,
                    reason: reasonController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    onRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.warning,
                        content: Text('Revizyon talebi iletildi.'),
                      ),
                    );
                  }
                },
                child: const Text('Revizyonu İlet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}