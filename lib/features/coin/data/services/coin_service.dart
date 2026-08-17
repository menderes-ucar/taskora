import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
    required String packageId,
    String? idempotencyKey,
  });

  // Admin İşlemleri
  Future<void> adminAddCoin(String userId, int amount, String reason);
  Future<void> adminDeductCoin(String userId, int amount, String reason);

  // Kategori Fiyatlandırması & Ayarlar
  Future<List<CoinPackage>> getActiveCoinPackages();
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
      throw AppException(
        message: 'Coin bakiyesi alınamadı: $e',
        type: AppExceptionType.serverError,
      );
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
      throw AppException(
        message: 'Coin işlem geçmişi alınamadı: $e',
        type: AppExceptionType.serverError,
      );
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
    if (amount <= 0) {
      throw AppException(
        message: 'Coin miktarı 0 dan büyük olmalıdır.',
        type: AppExceptionType.validation,
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw AppException(
        message: 'Oturum bulunamadı.',
        type: AppExceptionType.authentication,
      );
    }
    if (currentUserId != userId) {
      throw AppException(
        message: 'Bu coin hesabına erişim yetkiniz yok.',
        type: AppExceptionType.authorization,
      );
    }

    try {
      await _supabase.rpc('deduct_coins_secure', params: {
        'p_user_id': currentUserId,
        'p_amount': amount,
        'p_type': type.name,
        'p_related_id': relatedId,
        'p_description': description ?? 'Coin harcaması',
      });
    } catch (e) {
      throw AppException(
        message: e.toString(),
        type: AppExceptionType.serverError,
      );
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

  /// 6. Cüzdan bakiyesi ile coin paketi satın alma.
  /// Paket miktarı/fiyatı yalnızca server tarafından belirlenir.
  @override
  Future<bool> buyCoinPackage({
    required String packageId,
    String? idempotencyKey,
  }) async {
    final normalizedPackageId = packageId.trim();
    if (normalizedPackageId.isEmpty) {
      throw AppException(
        message: 'Geçersiz coin paketi.',
        type: AppExceptionType.validation,
      );
    }

    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw AppException(
        message: 'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
        type: AppExceptionType.authentication,
      );
    }

    final key = (idempotencyKey?.trim().isNotEmpty ?? false)
        ? idempotencyKey!.trim()
        : const Uuid().v4();

    try {
      await _supabase.rpc(
        'purchase_coin_package_atomic',
        params: {
          'p_package_id': normalizedPackageId,
          'p_idempotency_key': key,
        },
      );
      return true;
    } on PostgrestException catch (e) {
      throw AppException(
        message: _mapCoinError(e.message),
        type: AppExceptionType.serverError,
      );
    } catch (e) {
      throw AppException(
        message: e.toString(),
        type: AppExceptionType.serverError,
      );
    }
  }

  /// 7. Generic client-side refunds are intentionally disabled.
  /// Marketplace refunds must go through the refund queue and the atomic
  /// server-side refund workflow.
  @override
  Future<void> refundCoin(
      String userId,
      int amount,
      String reason, {
        String? relatedId,
      }) async {
    throw AppException(
      message: 'Doğrudan coin iadesi yapılamaz. İade akışını kullanın.',
      type: AppExceptionType.authorization,
    );
  }

  /// 8. Job teklif iadesi artık tek atomic server-side işlemle yapılır.
  @override
  Future<void> refundLosingFreelancers({
    required String jobId,
    required String acceptedFreelancerId,
  }) async {
    await _supabase.rpc('refund_job_proposals_atomic', params: {
      'p_job_id': jobId,
      'p_selected_freelancer_id': acceptedFreelancerId,
      'p_full_refund': false,
    });
  }

  /// 9. Admin İşlemleri
  @override
  Future<void> adminAddCoin(String userId, int amount, String reason) async {
    await _supabase.rpc('admin_adjust_coins_secure', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_operation': 'add',
      'p_reason': reason,
    });
  }

  @override
  Future<void> adminDeductCoin(String userId, int amount, String reason) async {
    await _supabase.rpc('admin_adjust_coins_secure', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_operation': 'deduct',
      'p_reason': reason,
    });
  }

  @override
  Future<List<CoinPackage>> getActiveCoinPackages() async {
    try {
      final response = await _supabase
          .from('coin_packages')
          .select('id,name,coin_amount,price_try,is_active,sort_order,store_product_id')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List<dynamic>)
          .map((json) => CoinPackage.fromMap(Map<String, dynamic>.from(json as Map)))
          .toList(growable: false);
    } catch (e) {
      throw AppException(
        message: 'Coin paketleri alınamadı: $e',
        type: AppExceptionType.serverError,
      );
    }
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
      return CoinPrice.fromMap(response);
    } catch (e) {
      print('❌ getCoinPriceByCategory error: $e');
      return null;
    }
  }

  @override
  Future<void> updateCoinPrice(CoinPrice coinPrice) async {
    try {
      await _supabase.rpc('admin_update_coin_price_secure', params: {
        'p_price_id': coinPrice.id,
        'p_proposal_cost': coinPrice.proposalCost,
      });
    } catch (e) {
      print('❌ updateCoinPrice error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createCoinPrice(CoinPrice coinPrice) async {
    try {
      await _supabase.rpc('admin_create_coin_price_secure', params: {
        'p_category_id': coinPrice.categoryId,
        'p_category_name': coinPrice.categoryName,
        'p_proposal_cost': coinPrice.proposalCost,
      });
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
    if (cost <= 0) {
      throw AppException(
        message: 'Mesaj coin maliyeti 0 dan büyük olmalıdır.',
        type: AppExceptionType.validation,
      );
    }

    await _supabase.rpc('admin_set_message_coin_cost_secure', params: {
      'p_cost': cost,
    });
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
    await _supabase.rpc('process_coin_refund_atomic', params: {
      'p_refund_id': refund.id,
    });
  }

  String _mapCoinError(String message) {
    switch (message) {
      case 'not_authenticated':
        return 'Oturum bulunamadı.';
      case 'coin_package_not_found':
        return 'Coin paketi artık satışta değil.';
      case 'wallet_not_found':
        return 'Cüzdan bulunamadı.';
      case 'insufficient_wallet_balance':
        return 'Yetersiz cüzdan bakiyesi.';
      case 'insufficient_coin_balance':
        return 'Yetersiz coin bakiyesi.';
      case 'profile_not_found':
        return 'Kullanıcı profili bulunamadı.';
      case 'invalid_amount':
        return 'Geçersiz coin paketi tutarı.';
      case 'idempotency_key_reused_with_different_package':
        return 'Bu satın alma anahtarı başka bir paket için kullanılmış.';
      case 'not_authorized':
        return 'Bu işlem için yetkiniz yok.';
      default:
        return message;
    }
  }
}

// Global Alias (Eski `CoinService` çağrılarının tamamını destekler)
typedef CoinService = SupabaseCoinService;