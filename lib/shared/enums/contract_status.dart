enum ContractStatus {
  active,
  delivered,
  completed,
  cancelled,
}

extension ContractStatusX on ContractStatus {
  String get label {
    switch (this) {
      case ContractStatus.active:
        return 'Aktif';
      case ContractStatus.delivered:
        return 'Teslim Edildi';
      case ContractStatus.completed:
        return 'Tamamlandı';
      case ContractStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}