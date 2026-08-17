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
  String? _processingRequestId;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final res = await _payoutService.getPayoutRequests();

      if (!mounted) return;

      setState(() {
        _requests = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Hata: $e'),
        ),
      );
    }
  }

  Future<void> _handleAction(
      Map<String, dynamic> request,
      String status,
      ) async {
    final requestId = request['id']?.toString();
    if (requestId == null || requestId.isEmpty) return;

    if (_processingRequestId != null) return;

    final isApprove = status == 'approved';
    final amount = _parseAmount(request['amount']);
    final profile = _profileFromRequest(request);
    final displayName = _displayName(profile);

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
              ? '$displayName hesabına ₺${amount.toStringAsFixed(2)} '
              'ödemeyi gerçekten yaptıysanız onaylayın.'
              : 'Talebi reddederseniz ₺${amount.toStringAsFixed(2)} '
              'tutar kullanıcının bakiyesine iade edilecektir.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isApprove ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isApprove ? 'Onayla (Ödendi)' : 'Reddet (İade Et)',
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _processingRequestId = requestId);

    try {
      await _payoutService.updatePayoutStatus(
        requestId: requestId,
        newStatus: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            isApprove
                ? 'Ödeme başarıyla onaylandı.'
                : 'Talep reddedildi ve tutar iade edildi.',
          ),
        ),
      );

      await _fetchRequests();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Hata: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingRequestId = null);
      }
    }
  }

  Map<String, dynamic> _profileFromRequest(
      Map<String, dynamic> request,
      ) {
    final rawProfile = request['profiles'];

    if (rawProfile is Map) {
      return Map<String, dynamic>.from(rawProfile);
    }

    return const <String, dynamic>{};
  }

  String _displayName(Map<String, dynamic> profile) {
    final name = profile['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = profile['email']?.toString().trim();
    if (email != null && email.isNotEmpty) return email;

    return 'Kullanıcı';
  }

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
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
          child: Text(
            'Henüz para çekme talebi yok.',
            style: TextStyle(color: Colors.white70),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchRequests,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final request = _requests[index];
              final profile = _profileFromRequest(request);
              final displayName = _displayName(profile);
              final status =
                  request['status']?.toString() ?? 'pending';
              final amount = _parseAmount(request['amount']);
              final bankName =
                  request['bank_name']?.toString() ?? '-';
              final bankAccount =
                  request['bank_account']?.toString() ?? '-';
              final requestId = request['id']?.toString();
              final isProcessing =
                  requestId != null &&
                      requestId == _processingRequestId;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₺${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hesap Sahibi: $displayName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Banka: $bankName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    SelectableText(
                      'IBAN / Hesap: $bankAccount',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(
                      color: Colors.white10,
                      height: 24,
                    ),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusBadge(status: status),
                        if (status == 'pending')
                          isProcessing
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : Row(
                            children: [
                              IconButton(
                                tooltip: 'Reddet ve iade et',
                                icon: const Icon(
                                  Icons.cancel,
                                  color: AppColors.danger,
                                ),
                                onPressed: () =>
                                    _handleAction(
                                      request,
                                      'rejected',
                                    ),
                              ),
                              IconButton(
                                tooltip: 'Ödendi olarak onayla',
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                onPressed: () =>
                                    _handleAction(
                                      request,
                                      'approved',
                                    ),
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color background, String text) = switch (status) {
      'approved' => (AppColors.success, 'ÖDENDİ'),
      'rejected' => (AppColors.danger, 'REDDEDİLDİ'),
      'cancelled' => (Colors.grey, 'İPTAL EDİLDİ'),
      _ => (Colors.orange, 'ONAY BEKLİYOR'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: background,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
