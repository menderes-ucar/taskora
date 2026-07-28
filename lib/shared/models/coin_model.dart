import 'package:intl/intl.dart';

/// Coin işlemi tipi
enum CoinTransactionType {
  purchase,      // Coin satın alma
  proposal,      // Teklif için harcama
  message,       // Mesaj için harcama
  refund,        // İade
  admin_add,     // Admin tarafından ekleme
  admin_deduct,  // Admin tarafından çıkarma
}

/// Coin işlem kaydı
class CoinTransaction {
  final String id;
  final String userId;
  final int amount;
  final CoinTransactionType type;
  final String? description;
  final String? relatedId; // İlgili iş/teklif/mesaj ID
  final DateTime createdAt;
  final int? balanceAfter; // İşlemden sonraki bakiye

  const CoinTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.description,
    this.relatedId,
    required this.createdAt,
    this.balanceAfter,
  });

  factory CoinTransaction.fromMap(Map<String, dynamic> map) {
    return CoinTransaction(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      type: _parseCoinTransactionType(map['type']),
      description: map['description'] as String?,
      relatedId: map['related_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      balanceAfter: (map['balance_after'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
      'balance_after': balanceAfter,
    };
  }

  static CoinTransactionType _parseCoinTransactionType(dynamic type) {
    if (type is String) {
      return CoinTransactionType.values.firstWhere(
            (e) => e.name == type.toLowerCase(),
        orElse: () => CoinTransactionType.purchase,
      );
    }
    return CoinTransactionType.purchase;
  }

  String get typeLabel {
    switch (type) {
      case CoinTransactionType.purchase:
        return 'Coin Satın Alma';
      case CoinTransactionType.proposal:
        return 'Teklif Gönderme';
      case CoinTransactionType.message:
        return 'Mesaj Gönderme';
      case CoinTransactionType.refund:
        return 'İade';
      case CoinTransactionType.admin_add:
        return 'Admin Ekleme';
      case CoinTransactionType.admin_deduct:
        return 'Admin Çıkarma';
    }
  }

  String get formattedDate => DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
}

/// Kategori bazında coin fiyatlandırması
class CoinPrice {
  final String id;
  final String categoryId;
  final String categoryName;
  final int proposalCost; // Teklif göndermek için coin maliyeti
  final DateTime updatedAt;
  final String? updatedBy; // Admin ID

  const CoinPrice({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.proposalCost,
    required this.updatedAt,
    this.updatedBy,
  });

  factory CoinPrice.fromMap(Map<String, dynamic> map) {
    return CoinPrice(
      id: map['id'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? '',
      categoryName: map['category_name'] as String? ?? 'Genel',
      proposalCost: (map['proposal_cost'] as num?)?.toInt() ?? 10,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      updatedBy: map['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'proposal_cost': proposalCost,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}

/// Coin geri ödeme kaydı (anlaşma iptal olduğunda)
class CoinRefund {
  final String id;
  final String proposalId;
  final String freelancerId;
  final int refundAmount;
  final String reason; // İş iptal, başka seçildi, vb.
  final DateTime refundedAt;
  final bool isProcessed;

  const CoinRefund({
    required this.id,
    required this.proposalId,
    required this.freelancerId,
    required this.refundAmount,
    required this.reason,
    required this.refundedAt,
    this.isProcessed = false,
  });

  factory CoinRefund.fromMap(Map<String, dynamic> map) {
    return CoinRefund(
      id: map['id'] as String? ?? '',
      proposalId: map['proposal_id'] as String? ?? '',
      freelancerId: map['freelancer_id'] as String? ?? '',
      refundAmount: (map['refund_amount'] as num?)?.toInt() ?? 0,
      reason: map['reason'] as String? ?? '',
      refundedAt: map['refunded_at'] != null
          ? DateTime.parse(map['refunded_at'] as String)
          : DateTime.now(),
      isProcessed: map['is_processed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proposal_id': proposalId,
      'freelancer_id': freelancerId,
      'refund_amount': refundAmount,
      'reason': reason,
      'refunded_at': refundedAt.toIso8601String(),
      'is_processed': isProcessed,
    };
  }
}
