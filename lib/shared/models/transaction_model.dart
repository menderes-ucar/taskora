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

  // Yeni eklendi
  final String status;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isIncome,
    this.status = 'completed',
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
    String? status,
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
      status: status ?? this.status,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: TransactionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => TransactionType.deposit,
      ),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      isIncome: map['is_income'] as bool? ?? false,
      status: map['status']?.toString() ?? 'completed',
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
      'status': status,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}