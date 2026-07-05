import '../enums/transaction_type.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isIncome;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isIncome,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    String? title,
    String? description,
    DateTime? createdAt,
    bool? isIncome,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => TransactionType.deposit,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isIncome: map['is_income'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type.name,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_income': isIncome,
    };
  }
}