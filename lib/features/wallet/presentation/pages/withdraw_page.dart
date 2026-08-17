import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_colors.dart';
import '../../providers/wallet_provider.dart';


class WithdrawPage extends ConsumerStatefulWidget {
  final String userId;

  const WithdrawPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  final _amountController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal(double currentBalance) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final bankName = _bankNameController.text.trim();
    final bankAccount = _bankAccountController.text.trim();
    final idempotencyKey = const Uuid().v4();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar girin')),
      );
      return;
    }

    if (amount > currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetersiz bakiye')),
      );
      return;
    }

    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum çekim tutarı ₺10 dir')),
          );
              return;
              }

              if (bankName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lütfen banka adını girin')),
      );
      return;
      }

          if (bankAccount.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen geçerli bir IBAN / hesap numarası girin')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Balance deduction + payout creation + withdrawal ledger entry happen
        // in one PostgreSQL transaction. The client never updates wallet balance.
        await Supabase.instance.client.rpc(
          'create_payout_request_atomic',
          params: {
            'p_amount': amount,
            'p_bank_name': bankName,
            'p_bank_account': bankAccount,
            'p_idempotency_key': idempotencyKey,
          },
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Para çekme talebi başarıyla oluşturuldu!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } on PostgrestException catch (e) {
        if (!mounted) return;

        final message = switch (e.message) {
          'insufficient_wallet_balance' => 'Yetersiz bakiye.',
          'wallet_not_found' => 'Cüzdan bulunamadı. Lütfen tekrar deneyin.',
          'minimum_payout_is_10' => 'Minimum çekim tutarı ₺10 dir.',
        'invalid_bank_account' => 'Geçersiz banka hesap bilgisi.',
        _ => 'Para çekme talebi oluşturulamadı.',
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.danger,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final currentBalance = walletAsync.value?.balance ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Para Çek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E2238), Color(0xFF103847), Color(0xFF0BA99C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kullanılabilir Bakiye', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('₺${currentBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Çekilecek Tutar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                prefixText: '₺ ',
                hintText: 'Tutar girin',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Banka Hesap Bilgileri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: _bankNameController,
              style: const TextStyle(color: AppColors.black),
              decoration: InputDecoration(hintText: 'Banka Adı', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankAccountController,
              style: const TextStyle(color: AppColors.black),
              decoration: InputDecoration(hintText: 'IBAN / Hesap Numarası', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submitWithdrawal(currentBalance),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Talep Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}