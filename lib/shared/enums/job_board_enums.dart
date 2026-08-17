// ====================================
// Job Board Enum'ları
// ====================================

/// Çalışma Şekli: Uzaktan, Hibrit veya Ofisten
enum WorkType {
  remote,    // Uzaktan (Remote)
  hybrid,    // Hibrit (Hybrid)
  onsite;    // Ofisten (On-site)

  factory WorkType.fromString(String value) {
    return WorkType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => WorkType.remote,
    );
  }

  String get label {
    switch (this) {
      case WorkType.remote:
        return 'Uzaktan (Remote)';
      case WorkType.hybrid:
        return 'Hibrit (Hybrid)';
      case WorkType.onsite:
        return 'Ofisten (On-site)';
    }
  }
}

/// Çalışma Modeli: Tam Zamanlı, Ücretsiz, Saatlik veya Staj
enum ContractType {
  paid,      // Tam Zamanlı / Maaşlı
  unpaid,    // Ücretsiz / Gönüllü
  contract,  // Saatlik / Proje Bazlı
  internship;// Stajyer / Staj

  factory ContractType.fromString(String value) {
    return ContractType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ContractType.paid,
    );
  }

  String get label {
    switch (this) {
      case ContractType.paid:
        return 'Tam Zamanlı / Maaşlı';
      case ContractType.unpaid:
        return 'Ücretsiz / Gönüllü';
      case ContractType.contract:
        return 'Saatlik / Proje Bazlı';
      case ContractType.internship:
        return 'Stajyer / Staj';
    }
  }
}

enum PostingStatus {
  pending,
  approved,
  rejected,
  closed;

  factory PostingStatus.fromString(String value) {
    return PostingStatus.values.firstWhere(
          (e) => e.name == value,
      orElse: () => PostingStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case PostingStatus.pending:
        return 'Onay Bekliyor';
      case PostingStatus.approved:
        return 'Yayında';
      case PostingStatus.rejected:
        return 'Reddedildi';
      case PostingStatus.closed:
        return 'Kapandı';
    }
  }
}

enum ApplicationStatus {
  pending,
  reviewed,
  accepted,
  rejected;

  factory ApplicationStatus.fromString(String value) {
    return ApplicationStatus.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ApplicationStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case ApplicationStatus.pending:
        return 'İnceleme Bekliyor';
      case ApplicationStatus.reviewed:
        return 'İncelendi';
      case ApplicationStatus.accepted:
        return 'Kabul Edildi';
      case ApplicationStatus.rejected:
        return 'Reddedildi';
    }
  }

  String get colorCode {
    switch (this) {
      case ApplicationStatus.pending:
        return '#F59E0B';
      case ApplicationStatus.reviewed:
        return '#3B82F6';
      case ApplicationStatus.accepted:
        return '#22C55E';
      case ApplicationStatus.rejected:
        return '#EF4444';
    }
  }
}