import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/config/coin_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../shared/models/coin_model.dart';

abstract class ICoinService {
  Future<List<CoinTransaction>> getUserCoinTransactions(String userId);
  Future<int> getUserCoinBalance(String userId);

  // Harcama & Düşüm Metodları
  Future<void> deductCoin(
      String userId,
      int amount,
      CoinTransactionType type, {
        String? relatedId,
        String? description,
      });
  Future<void> checkAndDeductCoins({
    required String userId,
    required int requiredCoins,
    required String actionDescription,
  });
  Future<bool> spendCoinsForProposal({
    required String freelancerId,
    required String jobId,
    required int coinAmount,
  });

  // İade Metodları
  Future<void> refundCoin(
      String userId,
      int amount,
      String reason, {
        String? relatedId,
      });
  Future<void> refundLosingFreelancers({
    required String jobId,
    required String acceptedFreelancerId,
  });

  // Cüzdan Bakiyesi (TL) İle Coin Paketi Satın Alma
  Future<bool> buyCoinPackage({
    required String userId,
    required int coinAmount,
    required double priceTL,
    required String packageName,
  });

  // Admin İşlemleri
  Future<void> adminAddCoin(String userId, int amount, String reason);
  Future<void> adminDeductCoin(String userId, int amount, String reason);

  // Kategori Fiyatlandırması & Ayarlar
  Future<List<CoinPrice>> getAllCoinPrices();
  Future<CoinPrice?> getCoinPriceByCategory(String categoryId);
  Future<void> updateCoinPrice(CoinPrice coinPrice);
  Future<void> createCoinPrice(CoinPrice coinPrice);
  Future<int> getMessageCoinCost();
  Future<void> setMessageCoinCost(int cost);

  // Refund Geçmişi
  Future<List<CoinRefund>> getPendingRefunds();
  Future<void> processCoinRefund(CoinRefund refund);
}

class SupabaseCoinService implements ICoinService {
  final SupabaseClient _supabase;

  SupabaseCoinService([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  /// 1. Kullanıcının Gerçek Coin Bakiyesini Getirir (`profiles` tablosu)
  @override
  Future<int> getUserCoinBalance(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('coins')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return 0;
      return (response['coins'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('❌ getUserCoinBalance error: $e');
      return 0;
    }
  }

  /// 2. Coin İşlem Geçmişini Getirir
  @override
  Future<List<CoinTransaction>> getUserCoinTransactions(String userId) async {
    try {
      final response = await _supabase
          .from('coin_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => CoinTransaction.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getUserCoinTransactions error: $e');
      return [];
    }
  }

  /// 3. Doğrudan Coin Düşme Metodu (proposal_service vs. için)
  @override
  Future<void> deductCoin(
      String userId,
      int amount,
      CoinTransactionType type, {
        String? relatedId,
        String? description,
      }) async {
    try {
      final currentBalance = await getUserCoinBalance(userId);

      if (currentBalance < amount) {
        throw Exception('Yeterli coin bulunmamaktadır! Mevcut: $currentBalance');
      }

      final newBalance = currentBalance - amount;

      await _supabase
          .from('profiles')
          .update({'coins': newBalance})
          .eq('id', userId);

      try {
        await _supabase.from('coin_transactions').insert({
          'user_id': userId,
          'amount': -amount,
          'type': type.name,
          'description': description ?? 'Coin harcaması',
          'related_id': relatedId,
          'created_at': DateTime.now().toIso8601String(),
          'balance_after': newBalance,
        });
      } catch (_) {}
    } catch (e) {
      print('❌ deductCoin error: $e');
      rethrow;
    }
  }

  /// 4. Kontrollü Coin Düşme (AppException fırlatan yapı)
  @override
  Future<void> checkAndDeductCoins({
    required String userId,
    required int requiredCoins,
    required String actionDescription,
  }) async {
    if (requiredCoins <= 0) return;

    try {
      await deductCoin(
        userId,
        requiredCoins,
        CoinTransactionType.proposal,
        description: actionDescription,
      );
    } catch (e) {
      throw AppException(
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppExceptionType.validation,
      );
    }
  }

  /// 5. Teklif Gönderirken Coin Düşme
  @override
  Future<bool> spendCoinsForProposal({
    required String freelancerId,
    required String jobId,
    required int coinAmount,
  }) async {
    try {
      await deductCoin(
        freelancerId,
        coinAmount,
        CoinTransactionType.proposal,
        relatedId: jobId,
        description: 'İlan ID: $jobId için teklif gönderildi.',
      );
      return true;
    } catch (e) {
      print('❌ spendCoinsForProposal error: $e');
      return false;
    }
  }

  /// 6. Cüzdan Bakiyesi (TL) İle Coin Paketi Satın Alma
  @override
  Future<bool> buyCoinPackage({
    required String userId,
    required int coinAmount,
    required double priceTL,
    required String packageName,
  }) async {
    try {
      final walletData = await _supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .single();

      final double currentBalance =
          (walletData['balance'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance < priceTL) {
        throw Exception(
            'Yetersiz bakiye! Lütfen önce cüzdanınıza TL yükleyin.');
      }

      // Cüzdandan TL Düş
      await _supabase
          .from('wallets')
          .update({'balance': currentBalance - priceTL})
          .eq('user_id', userId);

      // Profilde Coin Miktarını Artır
      final int currentCoins = await getUserCoinBalance(userId);
      final int newCoins = currentCoins + coinAmount;

      await _supabase
          .from('profiles')
          .update({'coins': newCoins})
          .eq('id', userId);

      // İşlem Geçmişine Kaydet
      await _supabase.from('transactions').insert({
        'user_id': userId,
        'amount': priceTL,
        'type': 'coin_purchase',
        'title': 'Coin Satın Alındı',
        'description': '$packageName ($coinAmount Coin) satın alındı.',
        'is_income': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 7. Coin İade Metodu
  @override
  Future<void> refundCoin(
      String userId,
      int amount,
      String reason, {
        String? relatedId,
      }) async {
    try {
      final currentBalance = await getUserCoinBalance(userId);
      final newBalance = currentBalance + amount;

      await _supabase
          .from('profiles')
          .update({'coins': newBalance})
          .eq('id', userId);

      try {
        await _supabase.from('coin_transactions').insert({
          'user_id': userId,
          'amount': amount,
          'type': CoinTransactionType.refund.name,
          'description': reason,
          'related_id': relatedId,
          'created_at': DateTime.now().toIso8601String(),
          'balance_after': newBalance,
        });
      } catch (_) {}
    } catch (e) {
      print('❌ refundCoin error: $e');
      rethrow;
    }
  }

  /// 8. Kaybeden Freelancer'lara İade Dağıtımı
  @override
  Future<void> refundLosingFreelancers({
    required String jobId,
    required String acceptedFreelancerId,
  }) async {
    try {
      final otherProposals = await _supabase
          .from('proposals')
          .select('id, freelancer_id')
          .eq('job_id', jobId)
          .neq('freelancer_id', acceptedFreelancerId)
          .eq('status', 'pending');

      if (otherProposals == null || (otherProposals as List).isEmpty) return;

      final int refundAmount =
      (CoinConstants.sendProposalCost * CoinConstants.proposalRefundRate)
          .toInt();

      for (var prop in otherProposals) {
        final String freelancerId = prop['freelancer_id'].toString();
        await refundCoin(
          freelancerId,
          refundAmount,
          'İlan başkasına verildiği için harcanan coin iade edildi.',
          relatedId: jobId,
        );
      }
    } catch (e) {
      print('❌ refundLosingFreelancers error: $e');
    }
  }

  /// 9. Admin İşlemleri
  @override
  Future<void> adminAddCoin(String userId, int amount, String reason) async {
    await refundCoin(userId, amount, 'Admin Eklemesi: $reason');
  }

  @override
  Future<void> adminDeductCoin(String userId, int amount, String reason) async {
    await deductCoin(
      userId,
      amount,
      CoinTransactionType.admin_deduct,
      description: 'Admin Kesintisi: $reason',
    );
  }

  /// 10. Kategori Fiyatlandırması Metodları (Admin Sayfası İçin)
  @override
  Future<List<CoinPrice>> getAllCoinPrices() async {
    try {
      final response = await _supabase
          .from('coin_prices')
          .select()
          .order('category_name', ascending: true);

      return (response as List<dynamic>)
          .map((json) => CoinPrice.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getAllCoinPrices error: $e');
      return [];
    }
  }

  @override
  Future<CoinPrice?> getCoinPriceByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('coin_prices')
          .select()
          .eq('category_id', categoryId)
          .maybeSingle();

      if (response == null) return null;
      return CoinPrice.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ getCoinPriceByCategory error: $e');
      return null;
    }
  }

  @override
  Future<void> updateCoinPrice(CoinPrice coinPrice) async {
    try {
      await _supabase
          .from('coin_prices')
          .update(coinPrice.toMap())
          .eq('id', coinPrice.id);
    } catch (e) {
      print('❌ updateCoinPrice error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createCoinPrice(CoinPrice coinPrice) async {
    try {
      await _supabase.from('coin_prices').insert(coinPrice.toMap());
    } catch (e) {
      print('❌ createCoinPrice error: $e');
      rethrow;
    }
  }

  /// 11. Mesaj Ücreti Metodları (Admin Sayfası İçin)
  @override
  Future<int> getMessageCoinCost() async {
    try {
      final response = await _supabase
          .from('settings')
          .select('value')
          .eq('key', 'message_coin_cost')
          .maybeSingle();

      if (response == null) return 3;
      return int.tryParse(response['value'].toString()) ?? 3;
    } catch (e) {
      print('❌ getMessageCoinCost error: $e');
      return 3;
    }
  }

  @override
  Future<void> setMessageCoinCost(int cost) async {
    try {
      final existing = await _supabase
          .from('settings')
          .select()
          .eq('key', 'message_coin_cost')
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('settings')
            .update({'value': cost.toString()})
            .eq('key', 'message_coin_cost');
      } else {
        await _supabase.from('settings').insert({
          'key': 'message_coin_cost',
          'value': cost.toString(),
        });
      }
    } catch (e) {
      print('❌ setMessageCoinCost error: $e');
      rethrow;
    }
  }

  /// 12. Refund Geçmişi Metodları
  @override
  Future<List<CoinRefund>> getPendingRefunds() async {
    try {
      final response = await _supabase
          .from('coin_refunds')
          .select()
          .eq('is_processed', false)
          .order('refunded_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => CoinRefund.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ getPendingRefunds error: $e');
      return [];
    }
  }

  @override
  Future<void> processCoinRefund(CoinRefund refund) async {
    try {
      await refundCoin(
        refund.freelancerId,
        refund.refundAmount,
        refund.reason,
        relatedId: refund.proposalId,
      );

      await _supabase
          .from('coin_refunds')
          .update({'is_processed': true})
          .eq('id', refund.id);
    } catch (e) {
      print('❌ processCoinRefund error: $e');
      rethrow;
    }
  }
}

// Global Alias (Eski `CoinService` çağrılarının tamamını destekler)
typedef CoinService = SupabaseCoinService;