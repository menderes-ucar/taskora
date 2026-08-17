import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContractTransactionException implements Exception {
  final String message;
  const ContractTransactionException(this.message);

  @override
  String toString() => message;
}

class ContractTransactionService {
  final SupabaseClient supabase;

  // Configuration - can be overridden for testing
  final int maxRetries;
  final Duration timeout;
  final Duration initialRetryDelay;

  ContractTransactionService(
      this.supabase, {
        this.maxRetries = 3,
        this.timeout = const Duration(seconds: 30),
        this.initialRetryDelay = const Duration(milliseconds: 500),
      });

  Future<dynamic> execute({
    required String rpc,
    required Map<String, dynamic> params,
  }) async {
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        final response = await supabase.rpc(
          rpc,
          params: params,
        ).timeout(timeout);

        // Null response is valid for void RPCs
        return response;
      } on TimeoutException {
        retryCount++;

        if (retryCount > maxRetries) {
          throw ContractTransactionException(
            'RPC timeout sonra $maxRetries defa yeniden denendi: $rpc',
          );
        }

        // Exponential backoff with jitter: 2^retryCount * initialDelay + random
        final exponentialDelay = initialRetryDelay * (1 << retryCount);
        final jitter = Duration(
          milliseconds:
          (exponentialDelay.inMilliseconds * 0.1 * (2 * 0.5)).toInt(),
        );
        await Future.delayed(exponentialDelay + jitter);
      } on PostgrestException catch (e) {
        // Don't retry on logical errors (validation, auth, etc)
        throw ContractTransactionException(
          'RPC hatası: ${e.message}',
        );
      } catch (e) {
        // Generic errors - could be network related, retry once
        if (retryCount < 1) {
          retryCount++;
          await Future.delayed(initialRetryDelay);
          continue;
        }
        throw ContractTransactionException(
          'RPC yürütülemedi: $rpc - ${e.toString()}',
        );
      }
    }

    throw ContractTransactionException(
      'RPC $maxRetries deneme sonra başarısız oldu: $rpc',
    );
  }
}
