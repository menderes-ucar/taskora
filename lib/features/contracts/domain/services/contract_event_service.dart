abstract class ContractEventService {

  Future<void> contractCreated({
    required String contractId,
    required String actorId,
    required Map<String, dynamic> metadata,
  });

  Future<void> escrowFunded({
    required String contractId,
    required String actorId,
  });

  Future<void> deliverySubmitted({
    required String contractId,
    required String actorId,
  });

  Future<void> revisionRequested({
    required String contractId,
    required String actorId,
  });

  Future<void> deliveryApproved({
    required String contractId,
    required String actorId,
  });

  Future<void> paymentReleased({
    required String contractId,
    required String actorId,
  });

  Future<void> disputeOpened({
    required String contractId,
    required String actorId,
  });

  Future<void> cancelRequested({
    required String contractId,
    required String actorId,
  });

  Future<void> ratingSubmitted({
    required String contractId,
    required String actorId,
    required int rating,
  });

}