enum PaymentStatus {
  pending,    // ödeme yapılmadı
  funded,     // escrow dolu
  released,   // freelancer aldı
  refunded,   // iade edildi
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Ödeme Bekleniyor';
      case PaymentStatus.funded:
        return 'Ödeme Güvence Altında';
      case PaymentStatus.released:
        return 'Ödeme Tamamlandı';
      case PaymentStatus.refunded:
        return 'İade Edildi';
    }
  }
}