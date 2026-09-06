import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/coin_model.dart';

class IapPurchaseResult {
  final bool success;
  final int coinAmount;
  final int balance;
  final String message;

  const IapPurchaseResult({
    required this.success,
    required this.coinAmount,
    required this.balance,
    required this.message,
  });
}

/// Store purchase coordinator for consumable coin packages.
///
/// The device never decides how many coins to grant. The store transaction is
/// sent to the server, verified there, and only then are coins credited by the
/// database RPC. This keeps the client outside the financial authority chain.
class IapCoinService {
  IapCoinService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isAvailable = false;
  bool _initialized = false;

  bool get isAvailable => _isAvailable;

  Future<void> initialize({
    required Future<void> Function(PurchaseDetails) onPurchase,
    required void Function(PurchaseDetails) onTerminalPurchase,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    _purchaseSubscription = _iap.purchaseStream.listen(
          (purchases) async {
        for (final purchase in purchases) {
          await _handlePurchase(purchase, onPurchase, onTerminalPurchase);
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('IAP purchase stream error: $error\n$stack');
      },
    );
  }

  Future<List<ProductDetails>> loadProducts(List<CoinPackage> packages) async {
    if (!_isAvailable) return const [];

    final ids = packages
        .map((package) => package.storeProductId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (ids.isEmpty) return const [];

    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      throw StateError(response.error!.message);
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs.join(', ')}');
    }

    return response.productDetails;
  }

  Future<void> buy(CoinPackage package) async {
    final productId = package.storeProductId.trim();
    if (productId.isEmpty) {
      throw StateError('Bu coin paketi için mağaza ürün kimliği tanımlanmamış.');
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.error != null) {
      throw StateError(response.error!.message);
    }

    if (response.productDetails.isEmpty) {
      throw StateError('Coin paketi mağazada bulunamadı.');
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    final started = await _iap.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: false,
    );

    if (!started) {
      throw StateError('Satın alma işlemi başlatılamadı.');
    }
  }


  Future<void> _handlePurchase(
      PurchaseDetails purchase,
      Future<void> Function(PurchaseDetails) onPurchase,
      void Function(PurchaseDetails) onTerminalPurchase,
      ) async {
    if (purchase.status == PurchaseStatus.pending) return;

    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      onTerminalPurchase(purchase);
      return;
    }

    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }

    try {
      // IMPORTANT: the server must successfully verify + credit the purchase
      // before the store transaction is consumed/completed. If verification
      // fails, we intentionally leave the purchase pending so it can be
      // retried instead of losing the customer's entitlement.
      await onPurchase(purchase);

      if (Platform.isAndroid) {
        final androidAddition =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final result = await androidAddition.consumePurchase(purchase);
        debugPrint('IAP consume result: ${result.responseCode}');
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      onTerminalPurchase(purchase);
    } catch (e, stack) {
      debugPrint('IAP verification/delivery failed: $e\n$stack');
      // DO NOT consume/complete a purchase when server delivery failed.
      // Google Play can then deliver the transaction again.
      onTerminalPurchase(purchase);
    }
  }

  Future<IapPurchaseResult> verifyAndDeliver(PurchaseDetails purchase) async {
    final response = await _supabase.functions.invoke(
      'verify-iap-purchase',
      body: {
        'source': purchase.verificationData.source,
        'product_id': purchase.productID,
        'purchase_id': purchase.purchaseID,
        'verification_data': purchase.verificationData.serverVerificationData,
        'transaction_date': purchase.transactionDate,
      },
    );

    if (response.data is! Map) {
      throw StateError('Satın alma doğrulaması başarısız oldu.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final success = data['success'] == true;
    if (!success) {
      throw StateError(data['message']?.toString() ?? 'Satın alma doğrulanamadı.');
    }

    final result = IapPurchaseResult(
      success: true,
      coinAmount: (data['coin_amount'] as num?)?.toInt() ?? 0,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      message: data['message']?.toString() ?? 'Coinler hesabınıza eklendi.',
    );

    debugPrint(
      'IAP delivered: product=${purchase.productID}, '
          'transaction=${purchase.purchaseID}, '
          'coinAmount=${result.coinAmount}, balance=${result.balance}',
    );

    return result;
  }


  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _initialized = false;
  }
}
