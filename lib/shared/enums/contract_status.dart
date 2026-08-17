enum ContractStatus {
  waitingPayment,
  funded,
  active,
  deliverySubmitted,
  underReview,
  revisionRequested,
  revisionInProgress,
  approved,
  paymentProcessing,
  completed,
  cancelRequested,
  cancelled,
  disputed,
  resolved,
}

extension ContractStatusX on ContractStatus {
  String get label {
    switch (this) {
      case ContractStatus.waitingPayment:
        return 'Ödeme Bekleniyor';
      case ContractStatus.funded:
        return 'Escrow Hazır';
      case ContractStatus.active:
        return 'Çalışılıyor';
      case ContractStatus.deliverySubmitted:
        return 'Teslim Edildi';
      case ContractStatus.underReview:
        return 'İnceleniyor';
      case ContractStatus.revisionRequested:
        return 'Revizyon İstendi';
      case ContractStatus.revisionInProgress:
        return 'Revizyon Yapılıyor';
      case ContractStatus.approved:
        return 'Onaylandı';
      case ContractStatus.paymentProcessing:
        return 'Ödeme İşleniyor';
      case ContractStatus.completed:
        return 'Tamamlandı';
      case ContractStatus.cancelRequested:
        return 'İptal Talebi';
      case ContractStatus.cancelled:
        return 'İptal Edildi';
      case ContractStatus.disputed:
        return 'Uyuşmazlık';
      case ContractStatus.resolved:
        return 'Çözüldü';
    }
  }

  bool get isActive {
    switch (this) {
      case ContractStatus.active:
      case ContractStatus.deliverySubmitted:
      case ContractStatus.underReview:
      case ContractStatus.revisionRequested:
      case ContractStatus.revisionInProgress:
      case ContractStatus.funded:
      case ContractStatus.waitingPayment:
        return true;
      default:
        return false;
    }
  }

  bool get isFinished {
    switch (this) {
      case ContractStatus.completed:
      case ContractStatus.cancelled:
      case ContractStatus.resolved:
        return true;
      default:
        return false;
    }
  }

  bool get canSubmitDelivery {
    return this == ContractStatus.active || this == ContractStatus.revisionInProgress;
  }

  bool get canApprove {
    return this == ContractStatus.deliverySubmitted || this == ContractStatus.underReview;
  }

  bool get canRequestRevision {
    return this == ContractStatus.deliverySubmitted || this == ContractStatus.underReview;
  }

  /// Only active contracts can open disputes
  bool get canOpenDispute {
    return this == ContractStatus.funded ||
        this == ContractStatus.active ||
        this == ContractStatus.deliverySubmitted ||
        this == ContractStatus.underReview ||
        this == ContractStatus.revisionRequested ||
        this == ContractStatus.revisionInProgress;
  }

  bool get canCancel {
    return !isFinished && this != ContractStatus.paymentProcessing && this != ContractStatus.disputed;
  }

  bool get canSubmitRating {
    return isFinished;
  }

  /// Validates if transition from this status to target is allowed
  bool canTransitionTo(ContractStatus target) {
    switch (this) {
      case ContractStatus.waitingPayment:
        return target == ContractStatus.funded || target == ContractStatus.cancelled;

      case ContractStatus.funded:
        return target == ContractStatus.active ||
            target == ContractStatus.cancelRequested ||
            target == ContractStatus.disputed;

      case ContractStatus.active:
        return target == ContractStatus.deliverySubmitted ||
            target == ContractStatus.cancelRequested ||
            target == ContractStatus.disputed;

      case ContractStatus.deliverySubmitted:
        return target == ContractStatus.underReview ||
            target == ContractStatus.approved ||
            target == ContractStatus.revisionRequested ||
            target == ContractStatus.disputed;

      case ContractStatus.underReview:
        return target == ContractStatus.approved ||
            target == ContractStatus.revisionRequested ||
            target == ContractStatus.disputed;

      case ContractStatus.revisionRequested:
        return target == ContractStatus.revisionInProgress || target == ContractStatus.disputed;

      case ContractStatus.revisionInProgress:
        return target == ContractStatus.deliverySubmitted;

      case ContractStatus.approved:
        return target == ContractStatus.paymentProcessing;

      case ContractStatus.paymentProcessing:
        return target == ContractStatus.completed;

      case ContractStatus.cancelRequested:
        return target == ContractStatus.cancelled ||
            target == ContractStatus.active ||
            target == ContractStatus.disputed;

      case ContractStatus.disputed:
        return target == ContractStatus.resolved;

      case ContractStatus.resolved:
        return target == ContractStatus.completed || target == ContractStatus.cancelled;

      case ContractStatus.completed:
        return false;

      case ContractStatus.cancelled:
        return false;
    }
  }

  static ContractStatus? fromStringOrNull(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final normalized = value.toLowerCase().replaceAll('_', '');

    switch (normalized) {
      case 'waitingpayment':
        return ContractStatus.waitingPayment;
      case 'funded':
        return ContractStatus.funded;
      case 'active':
        return ContractStatus.active;
      case 'submitted':
      case 'deliverysubmitted':
      case 'worksubmitted':
      case 'delivered':
        return ContractStatus.deliverySubmitted;
      case 'underreview':
        return ContractStatus.underReview;
      case 'revisionrequested':
        return ContractStatus.revisionRequested;
      case 'revisioninprogress':
        return ContractStatus.revisionInProgress;
      case 'approved':
        return ContractStatus.approved;
      case 'paymentprocessing':
        return ContractStatus.paymentProcessing;
      case 'completed':
        return ContractStatus.completed;
      case 'cancelrequested':
        return ContractStatus.cancelRequested;
      case 'cancelled':
        return ContractStatus.cancelled;
      case 'disputed':
        return ContractStatus.disputed;
      case 'resolved':
        return ContractStatus.resolved;
      default:
        return null;
    }
  }

  /// Parses with default fallback for backward compatibility
  static ContractStatus fromString(String? value) {
    return fromStringOrNull(value) ?? ContractStatus.waitingPayment;
  }
}
