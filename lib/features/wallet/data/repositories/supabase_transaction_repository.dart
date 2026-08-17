import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/enums/transaction_type.dart';
import '../../../../../shared/models/transaction_model.dart';
import '../../../../../core/error/app_exception.dart';
import 'transaction_repository.dart';

class SupabaseTransactionRepository implements TransactionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        TransactionType type;
        final rawType = json['type']?.toString();

        if (rawType == 'coin_spend') {
          type = TransactionType.escrowFunding;
        } else if (rawType == 'refund') {
          type = TransactionType.refund;
        } else if (rawType == 'withdrawal') {
          type = TransactionType.withdrawal;
        } else {
          type = TransactionType.deposit;
        }

        return TransactionModel(
          id: json['id']?.toString() ?? '',
          userId: json['user_id']?.toString() ?? '',
          amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
          type: type,
          title: json['title']?.toString() ?? 'İşlem',
          description: json['description']?.toString() ?? '',
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
          isIncome: json['is_income'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    throw StateError(
      'Muhasebe işlemleri istemciden doğrudan oluşturulamaz.',
    );
  }
}