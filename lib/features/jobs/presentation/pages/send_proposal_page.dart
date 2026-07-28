import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/config/coin_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/proposal_service.dart';
import '../../../../shared/enums/proposal_status.dart';
import '../../../../shared/models/proposal_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';

class SendProposalPage extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;
  final String jobCategory;

  const SendProposalPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.jobCategory,
  });

  @override
  ConsumerState<SendProposalPage> createState() => _SendProposalPageState();
}

class _SendProposalPageState extends ConsumerState<SendProposalPage> {
  final _formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final deliveryDaysController = TextEditingController();
  final coverLetterController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    amountController.dispose();
    deliveryDaysController.dispose();
    coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    // 🛑 0. Çift Tıklama (Double-Click) ve Form Doğrulama Koruması
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider).user;
    final supabaseUser = Supabase.instance.client.auth.currentUser;

    final userId = currentUser?.id ?? supabaseUser?.id;
    final userEmail =
        currentUser?.email ?? supabaseUser?.email ?? 'freelancer@taskora.com';

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final int requiredCoins = CoinConstants.getCost(widget.jobCategory);

      // 🚀 ProposalModel oluşturuluyor
      final proposal = ProposalModel(
        id: '',
        jobId: widget.jobId,
        freelancerId: userId,
        freelancerName: userEmail.split('@').first,
        amount: double.tryParse(amountController.text.trim()) ?? 0,
        deliveryDays: int.tryParse(deliveryDaysController.text.trim()) ?? 1,
        coverLetter: coverLetterController.text.trim(),
        status: ProposalStatus.pending,
        createdAt: DateTime.now(),
        coinCost: requiredCoins,
      );

      await createProposalWithCoinDeduction(
        supabase: supabase,
        proposal: proposal,
        coinCost: requiredCoins,
        jobCategoryId: widget.jobCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Teklif başarıyla gönderildi! 🪙'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('PostgrestException(', '')
            .split(', code:')
            .first
            .trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              cleanMsg,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('Teklif Ver'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.jobTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Teklif tutarı (₺)'),
              validator: (v) => v == null || v.isEmpty ? 'Tutar girin' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: deliveryDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Teslim süresi (gün)'),
              validator: (v) => v == null || v.isEmpty ? 'Süre girin' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: coverLetterController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Teklif açıklaması'),
              validator: (value) =>
              value == null || value.isEmpty ? 'Açıklama girin' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitProposal,
              child: Text(_isSubmitting ? 'Gönderiliyor...' : 'Teklifi Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}