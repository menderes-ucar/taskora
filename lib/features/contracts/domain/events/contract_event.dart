enum ContractEventType {
  contractCreated,
  escrowFunded,
  deliverySubmitted,
  revisionRequested,
  deliveryApproved,
  paymentReleased,
  disputeOpened,
  cancelRequested,
  ratingSubmitted,
}

class ContractEvent {
  final ContractEventType type;
  final String contractId;
  final String actorId;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  const ContractEvent({
    required this.type,
    required this.contractId,
    required this.actorId,
    required this.createdAt,
    this.payload,
  });
}
