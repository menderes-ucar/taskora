enum ContractStatus {
  waitingPayment,   // Ödeme bekleniyor (Escrow)
  funded,           // Ödeme havuza alındı
  active,           // Freelancer çalışıyor
  submitted,        // İnceleme bekliyor (Teslimat yapıldı)
  revisionRequested,// Revizyon istendi
  completed,        // Onaylandı & Ödeme Aktarıldı
  disputed,         // Uyuşmazlık açıldı (Admin)
  cancelled,        // İptal edildi
}

extension ContractStatusX on ContractStatus {
  String get label {
    switch (this) {
      case ContractStatus.waitingPayment:
        return 'Ödeme Bekleniyor';
      case ContractStatus.funded:
        return 'Ödeme Havuzda';
      case ContractStatus.active:
        return 'Devam Ediyor';
      case ContractStatus.submitted:
        return 'Teslim Edildi (Onay Bekliyor)';
      case ContractStatus.revisionRequested:
        return 'Revizyon İstendi';
      case ContractStatus.completed:
        return 'Tamamlandı';
      case ContractStatus.disputed:
        return 'Uyuşmazlık Açıldı';
      case ContractStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  static ContractStatus fromString(String? value) {
    if (value == null) return ContractStatus.active;
    switch (value.toLowerCase()) {
      case 'waitingpayment':
      case 'waiting_payment':
        return ContractStatus.waitingPayment;
      case 'funded':
        return ContractStatus.funded;
      case 'submitted':
      case 'work_submitted':
      case 'worksubmitted':
      case 'delivered':
        return ContractStatus.submitted;
      case 'revisionrequested':
      case 'revision_requested':
        return ContractStatus.revisionRequested;
      case 'completed':
        return ContractStatus.completed;
      case 'disputed':
        return ContractStatus.disputed;
      case 'cancelled':
        return ContractStatus.cancelled;
      case 'active':
      default:
        return ContractStatus.active;
    }
  }
}