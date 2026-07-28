import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../admin_guard.dart';
import '../../data/admin_payout_service.dart';

class AdminPayoutsPage extends StatefulWidget {
  const AdminPayoutsPage({super.key});

  @override
  State<AdminPayoutsPage> createState() => _AdminPayoutsPageState();
}

class _AdminPayoutsPageState extends State<AdminPayoutsPage> {
  final _payoutService = AdminPayoutService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _payoutService.getPayoutRequests();
      setState(() {
        _requests = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text('Hata: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(Map<String, dynamic> req, String status) async {
    final isApprove = status == 'approved';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          isApprove ? 'Ödemeyi Onayla' : 'Talebi Reddet',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isApprove
              ? '${req['account_holder']} hesabına ₺${req['amount']} ödemeyi yaptıysanız onaylayın.'
              : 'Talebi reddederseniz tutar kullanıcının bakiyesine iade edilecektir.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isApprove ? 'Onayla (Ödendi)' : 'Reddet (İade Et)'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _payoutService.updatePayoutStatus(
        requestId: req['id'],
        userId: req['user_id'],
        amount: (req['amount'] as num).toDouble(),
        newStatus: status,
      );
      _fetchRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          title: const Text('Para Çekme Talepleri'),
          backgroundColor: AppColors.dark,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
            ? const Center(
          child: Text('Henüz para çekme talebi yok.', style: TextStyle(color: Colors.white70)),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _requests.length,
          itemBuilder: (context, i) {
            final req = _requests[i];
            final profile = req['profiles'] ?? {};
            final status = req['status'] ?? 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        profile['name'] ?? profile['email'] ?? 'Kullanıcı',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '₺${req['amount']}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Hesap Sahibi: ${req['account_holder']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Banka: ${req['bank_name']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  SelectableText('IBAN: ${req['iban']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusBadge(status: status),
                      if (status == 'pending')
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cancel, color: AppColors.danger),
                              onPressed: () => _handleAction(req, 'rejected'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: AppColors.success),
                              onPressed: () => _handleAction(req, 'approved'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String text;

    switch (status) {
      case 'approved':
        bg = AppColors.success;
        text = 'ÖDENDİ';
        break;
      case 'rejected':
        bg = AppColors.danger;
        text = 'REDDEDİLDİ';
        break;
      default:
        bg = Colors.orange;
        text = 'ONAY BEKLİYOR';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}