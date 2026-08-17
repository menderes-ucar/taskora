import 'package:flutter/foundation.dart';

import 'contract_event_service.dart';
import 'contract_audit_service.dart';

class ContractEventServiceImpl implements ContractEventService {
  final ContractAuditService audit;

  ContractEventServiceImpl(this.audit);

  /// Safely logs event with fallback on failure
  Future<void> _safeLog({
    required String contractId,
    required String actorId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await audit.log(
        contractId: contractId,
        actorId: actorId,
        action: action,
        metadata: metadata,
      );
    } catch (e) {
      // Log failure but don't crash the workflow
      // In production, this should notify monitoring
      debugPrint(
        '[ContractEvent] audit logging failed '
            'action=$action contract=$contractId error=$e',
      );
    }
  }

  @override
  Future<void> contractCreated({
    required String contractId,
    required String actorId,
    required Map<String, dynamic> metadata,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'contract_created',
      metadata: metadata,
    );
  }

  @override
  Future<void> escrowFunded({
    required String contractId,
    required String actorId,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'escrow_funded',
      metadata: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> deliverySubmitted({
    required String contractId,
    required String actorId,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'delivery_submitted',
      metadata: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> revisionRequested({
    required String contractId,
    required String actorId,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'revision_requested',
      metadata: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> deliveryApproved({
    required String contractId,
    required String actorId,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'delivery_approved',
      metadata: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> paymentReleased({
    required String contractId,
    required String actorId,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'payment_released',
      metadata: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> disputeOpened({
    required String contractId,
    required String actorId,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'dispute_opened',
      metadata: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> cancelRequested({
    required String contractId,
    required String actorId,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'cancel_requested',
      metadata: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> ratingSubmitted({
    required String contractId,
    required String actorId,
    required int rating,
  }) async {
    await _safeLog(
      contractId: contractId,
      actorId: actorId,
      action: 'rating_submitted',
      metadata: {
        'rating': rating,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
