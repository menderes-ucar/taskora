
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_colors.dart';

abstract class IPaymentService {
  Future<void> processPayment({
    required double amount,
    required String currency,
    required String description,
  });
}

class StripePaymentService implements IPaymentService {
  final SupabaseClient _supabase;

  StripePaymentService(this._supabase);

  @override
  Future<void> processPayment({
    required double amount,
    required String currency,
    required String description,
  }) async {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');

    final idempotencyKey = const Uuid().v4();

    final response = await _supabase.functions.invoke(
      'create-payment-intent',
      body: {
        'amount': amount,
        'currency': currency.toLowerCase(),
        'description': description,
        'idempotency_key': idempotencyKey,
      },
    );

    if (response.data is! Map) {
      throw StateError('Ödeme oturumu oluşturulamadı.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final clientSecret = data['client_secret']?.toString();

    if (clientSecret == null || clientSecret.isEmpty) {
      throw StateError('Ödeme oturumu oluşturulamadı.');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Taskora',
        style: ThemeMode.system,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // Wallet credit is intentionally NOT performed here. Stripe's signed
    // webhook is the authoritative settlement source and the database
    // settlement function is idempotent.
  }
}

class PaymentResult {
  final bool success;
  final String? error;
  PaymentResult({required this.success, this.error});
}

final paymentServiceProvider = Provider<IPaymentService>((ref) {
  return StripePaymentService(Supabase.instance.client);
});

class AddFundsPage extends ConsumerStatefulWidget {
  final String userId;
  final double? initialAmount;

  const AddFundsPage({
    super.key,
    required this.userId,
    this.initialAmount,
  });

  @override
  ConsumerState<AddFundsPage> createState() => _AddFundsPageState();
}

class _AddFundsPageState extends ConsumerState<AddFundsPage> {
  late TextEditingController _amountController;
  String _selectedPaymentMethod = 'credit_card';
  bool _isLoading = false;
  double _selectedAmount = 0;

  final List<double> _quickAmounts = [50, 100, 250, 500];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _selectedAmount = widget.initialAmount ?? 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addFunds() async {
    double amount = _selectedAmount > 0
        ? _selectedAmount
        : double.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (Stripe.publishableKey.trim().isEmpty) {
        throw StateError(
          'Stripe ödeme anahtarı yapılandırılmamış. .env dosyasına STRIPE_PUBLISHABLE_KEY ekleyin.',
        );
      }

      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.processPayment(
        amount: amount,
        currency: 'try',
        description: 'Taskora cüzdan bakiyesi yükleme',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme tamamlandı. ₺${amount.toStringAsFixed(2)} bakiyeniz doğrulama sonrası hesabınıza yansıtılacak.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInputAmount = _selectedAmount > 0 ? _selectedAmount : double.tryParse(_amountController.text) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text(
          'Bakiye Ekle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Seçim',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.3,
              children: _quickAmounts
                  .map((amount) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amount;
                    _amountController.text = '';
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedAmount == amount ? AppColors.primaryDark : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedAmount == amount ? AppColors.primaryDark : AppColors.primaryDark.withValues(alpha: 0.20),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '₺$amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _selectedAmount == amount ? Colors.white : AppColors.black,
                      ),
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Farklı Tutar Gir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() => _selectedAmount = 0);
              },
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                prefixText: '₺ ',
                hintText: 'Tutar girin',
                hintStyle: const TextStyle(color: AppColors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.primaryDark,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ödeme Yöntemi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodOption('credit_card', 'Kredi / Banka Kartı', Icons.credit_card),
            const SizedBox(height: 10),
            _buildPaymentMethodOption('paypal', 'PayPal', Icons.account_balance_wallet),
            const SizedBox(height: 10),
            _buildPaymentMethodOption('bank_transfer', 'Banka Transferi (EFT)', Icons.account_balance),
            const SizedBox(height: 24),

            // İşlem Detay Kutusu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryDark.withValues(alpha: 0.20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İşlem Detayları',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                      fontSize: 15,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tutar:',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₺${currentInputAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Komisyon (2.9%):',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₺${(currentInputAmount * 0.029).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toplam Tutar:',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        '₺${(currentInputAmount * 1.029).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.success,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addFunds,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Bakiyeyi Yükle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.primaryDark.withValues(alpha: 0.20),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primaryDark,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}