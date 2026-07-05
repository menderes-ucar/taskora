enum JobStatus {
  open,
  inProgress,
  completed,
  cancelled,
}

extension JobStatusX on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.open:
        return 'Açık';
      case JobStatus.inProgress:
        return 'Devam Ediyor';
      case JobStatus.completed:
        return 'Tamamlandı';
      case JobStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}