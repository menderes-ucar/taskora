import 'package:supabase_flutter/supabase_flutter.dart';

class ContractAuditException implements Exception {
  final String message;
  const ContractAuditException(this.message);

  @override
  String toString() => message;
}

class ContractAuditService {
  final SupabaseClient supabase;

  ContractAuditService(this.supabase);

  static const int _maxRetry = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  Future<void> log({
    required String contractId,
    required String actorId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    int retryCount = 0;

    while (retryCount <= _maxRetry) {
      try {
        await supabase.from('contract_audit_logs').insert({
          'contract_id': contractId,
          'actor_id': actorId,
          'action': action,
          'metadata': metadata,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        return;
      } on PostgrestException catch (e) {
        if (retryCount < _maxRetry && _isRetryableError(e)) {
          retryCount++;
          await Future.delayed(_retryDelay * retryCount);
          continue;
        }
        throw ContractAuditException(
          'Denetim günlüğü yazılamadı: ${e.message}',
        );
      } catch (e) {
        throw ContractAuditException(
          'Denetim günlüğü yazılamadı: ${e.toString()}',
        );
      }
    }
  }

  bool _isRetryableError(PostgrestException e) {
    // Retry on network errors or server errors (5xx)
    final code = e.code;
    return code == null ||
        code.contains('08') ||
        code.startsWith('5');
  }
}
