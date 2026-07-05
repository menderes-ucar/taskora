enum TransactionType {
  deposit,
  escrowFunding,
  paymentRelease,
  refund,
}

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.deposit:
        return 'Bakiye Yükleme';
      case TransactionType.escrowFunding:
        return 'Escrow Ödemesi';
      case TransactionType.paymentRelease:
        return 'Ödeme Serbest Bırakma';
      case TransactionType.refund:
        return 'İade';
    }
  }
}