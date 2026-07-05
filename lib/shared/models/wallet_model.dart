class WalletModel {
  final String userId;
  final double balance;

  const WalletModel({
    required this.userId,
    required this.balance,
  });

  WalletModel copyWith({
    String? userId,
    double? balance,
  }) {
    return WalletModel(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
    );
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      userId: map['user_id'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'balance': balance,
    };
  }
}