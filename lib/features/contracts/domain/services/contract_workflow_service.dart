import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../data/contract_repository.dart';
import 'contract_transaction_service.dart';
import 'contract_event_service.dart';

class ContractWorkflowException implements Exception {
  final String message;
  const ContractWorkflowException(this.message);

  @override
  String toString() => message;
}

class ContractWorkflowService {
  final IContractRepository repository;
  final ContractEventService eventService;
  final ContractTransactionService transaction;

  ContractWorkflowService(
      this.repository,
      this.eventService,
      this.transaction,
      );

  bool _isEmployer(ContractModel contract, String userId) {
    return contract.employerId == userId;
  }

  bool _isFreelancer(ContractModel contract, String userId) {
    return contract.freelancerId == userId;
  }

  void _ensureEmployer(ContractModel contract, String userId) {
    if (!_isEmployer(contract, userId)) {
      throw const ContractWorkflowException(
        'Bu işlem sadece Employer tarafından yapılabilir.',
      );
    }
  }

  void _ensureFreelancer(ContractModel contract, String userId) {
    if (!_isFreelancer(contract, userId)) {
      throw const ContractWorkflowException(
        'Bu işlem sadece Freelancer tarafından yapılabilir.',
      );
    }
  }

  Future<ContractModel> _getContractOrThrow(String contractId) async {
    final contract = await repository.getById(contractId);

    if (contract == null) {
      throw const ContractWorkflowException('Contract bulunamadı.');
    }

    return contract;
  }

  Future<ContractModel> _getEmployerContract(
      String contractId,
      String actorId,
      ) async {
    final contract = await _getContractOrThrow(contractId);
    _ensureEmployer(contract, actorId);
    return contract;
  }

  Future<ContractModel> _getFreelancerContract(
      String contractId,
      String actorId,
      ) async {
    final contract = await _getContractOrThrow(contractId);
    _ensureFreelancer(contract, actorId);
    return contract;
  }

  Future<void> createContract(ContractModel contract) async {
    if (contract.jobId.isEmpty) {
      throw const ContractWorkflowException('Job id boş olamaz.');
    }

    if (contract.employerId.isEmpty) {
      throw const ContractWorkflowException('Employer bulunamadı.');
    }

    if (contract.freelancerId.isEmpty) {
      throw const ContractWorkflowException('Freelancer bulunamadı.');
    }

    if (contract.agreedAmount <= 0) {
      throw const ContractWorkflowException('Geçersiz sözleşme tutarı.');
    }

    if (contract.deliveryDays <= 0) {
      throw const ContractWorkflowException('Teslim süresi 0 günden fazla olmalıdır.');
    }

    await transaction.execute(
      rpc: 'create_contract_rpc',
      params: {
        'p_job_id': contract.jobId,
        'p_job_title': contract.jobTitle,
        'p_employer_id': contract.employerId,
        'p_freelancer_id': contract.freelancerId,
        'p_freelancer_name': contract.freelancerName,
        'p_agreed_amount': contract.agreedAmount,
        'p_delivery_days': contract.deliveryDays,
      },
    );

    await eventService.contractCreated(
      contractId: contract.id,
      actorId: contract.employerId,
      metadata: {
        'amount': contract.agreedAmount,
        'freelancer': contract.freelancerId,
        'days': contract.deliveryDays,
      },
    );
  }

  // ------------------------------------------------------------------
  // ESCROW
  // ------------------------------------------------------------------

  Future<void> fundEscrow({
    required String contractId,
    required String actorId,
  }) async {
    final contract = await _getEmployerContract(contractId, actorId);

    if (contract.status != ContractStatus.waitingPayment) {
      throw const ContractWorkflowException('Escrow daha önce oluşturulmuş.');
    }

    if (contract.agreedAmount <= 0) {
      throw ContractWorkflowException(
        'Geçersiz ödeme tutarı: ${contract.agreedAmount}',
      );
    }

    await transaction.execute(
      rpc: 'fund_contract_escrow_rpc',
      params: {
        'p_contract_id': contractId,
        'p_actor_id': actorId,
      },
    );

    await eventService.escrowFunded(
      contractId: contractId,
      actorId: actorId,
    );
  }

  Future<void> releaseEscrow({
    required String contractId,
    required String actorId,
  }) async {
    final contract = await _getEmployerContract(contractId, actorId);

    if (contract.status != ContractStatus.approved) {
      throw const ContractWorkflowException('Ödeme şu an serbest bırakılamaz.');
    }

    await transaction.execute(
      rpc: 'release_payment_rpc',
      params: {
        'p_contract_id': contractId,
        'p_actor_id': actorId,
      },
    );

    await eventService.paymentReleased(
      contractId: contractId,
      actorId: actorId,
    );
  }

  // ------------------------------------------------------------------
  // DELIVERY
  // ------------------------------------------------------------------

  Future<Map<String, dynamic>> submitDelivery({
    required String contractId,
    required String actorId,
    required String message,
    String? fileUrl,
  }) async {
    final contract = await _getFreelancerContract(contractId, actorId);

    if (!contract.status.canSubmitDelivery) {
      throw const ContractWorkflowException('Bu aşamada teslim yapılamaz.');
    }

    if (message.trim().isEmpty) {
      throw const ContractWorkflowException('Teslim mesajı boş olamaz.');
    }

    // Prevent duplicate submissions
    if (contract.submittedAt != null &&
        contract.status == ContractStatus.deliverySubmitted) {
      throw const ContractWorkflowException('Teslimat zaten yapılmış.');
    }

    final response = await transaction.execute(
      rpc: 'submit_delivery_rpc',
      params: {
        'p_contract_id': contractId,
        'p_actor_id': actorId,
        'p_message': message.trim(),
        'p_file_url': fileUrl,
      },
    );

    await eventService.deliverySubmitted(
      contractId: contractId,
      actorId: actorId,
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw const ContractWorkflowException(
      'Teslimat oluşturuldu ancak RPC teslimat bilgisini döndürmedi.',
    );
  }

  Future<void> approveDelivery({
    required String contractId,
    required String actorId,
  }) async {
    final contract = await _getEmployerContract(contractId, actorId);

    if (!contract.status.canApprove) {
      throw const ContractWorkflowException('Teslimat bu aşamada onaylanamaz.');
    }

    await transaction.execute(
      rpc: 'approve_delivery_rpc',
      params: {
        'p_contract_id': contractId,
        'p_actor_id': actorId,
      },
    );

    await eventService.deliveryApproved(
      contractId: contractId,
      actorId: actorId,
    );
  }

  Future<void> requestRevision({
    required String contractId,
    required String actorId,
    required String reason,
  }) async {
    final contract = await _getEmployerContract(contractId, actorId);

    if (!contract.status.canRequestRevision) {
      throw const ContractWorkflowException('Bu aşamada revizyon istenemez.');
    }

    if (reason.trim().isEmpty) {
      throw const ContractWorkflowException('Revizyon nedeni boş olamaz.');
    }

    if (contract.revisionCount >= contract.maxRevisionCount) {
      throw ContractWorkflowException(
        'Maksimum revizyon sayısına ulaşıldı (${contract.maxRevisionCount}).',
      );
    }

    await transaction.execute(
      rpc: 'request_contract_revision_rpc',
      params: {
        'p_contract_id': contractId,
        'p_actor_id': actorId,
        'p_revision_note': reason.trim(),
      },
    );

    await eventService.revisionRequested(
      contractId: contractId,
      actorId: actorId,
    );
  }

  // ------------------------------------------------------------------
  // DISPUTE
  // ------------------------------------------------------------------

  Future<void> openDispute({
    required String contractId,
    required String actorId,
    required String reason,
  }) async {
    final contract = await _getContractOrThrow(contractId);

    if (!_isEmployer(contract, actorId) &&
        !_isFreelancer(contract, actorId)) {
      throw const ContractWorkflowException('Bu işlem için yetkiniz yok.');
    }

    if (!contract.status.canOpenDispute) {
      throw const ContractWorkflowException('Bu aşamada dispute açılamaz.');
    }

    if (reason.trim().isEmpty) {
      throw const ContractWorkflowException('Uyuşmazlık nedeni boş olamaz.');
    }

    if (contract.disputeOpened) {
      throw const ContractWorkflowException('Bu sözleşmede zaten bir uyuşmazlık açılmış.');
    }

    await transaction.execute(
      rpc: 'open_dispute_rpc',
      params: {
        'p_contract_id': contractId,
        'p_actor_id': actorId,
        'p_reason': reason.trim(),
      },
    );

    await eventService.disputeOpened(
      contractId: contractId,
      actorId: actorId,
    );
  }

  // ------------------------------------------------------------------
  // CANCEL
  // ------------------------------------------------------------------

  Future<void> requestCancel({
    required String contractId,
    required String actorId,
    required String reason,
  }) async {
    final contract = await _getContractOrThrow(contractId);

    if (!_isEmployer(contract, actorId) && !_isFreelancer(contract, actorId)) {
      throw const ContractWorkflowException('Bu işlem için yetkiniz yok.');
    }

    if (!contract.status.canCancel) {
      throw const ContractWorkflowException('Bu sözleşme iptal edilemez.');
    }

    if (reason.trim().isEmpty) {
      throw const ContractWorkflowException('İptal nedeni boş olamaz.');
    }

    await transaction.execute(
      rpc: 'request_cancel_rpc',
      params: {
        'p_contract_id': contractId,
        'p_actor_id': actorId,
        'p_reason': reason.trim(),
      },
    );

    await eventService.cancelRequested(
      contractId: contractId,
      actorId: actorId,
    );
  }

  // ------------------------------------------------------------------
  // RATING
  // ------------------------------------------------------------------

  Future<void> submitRating({
    required String contractId,
    required String reviewerId,
    required int rating,
    required String review,
  }) async {
    final contract = await _getContractOrThrow(contractId);

    if (!contract.status.canSubmitRating) {
      throw const ContractWorkflowException('Sadece tamamlanan sözleşmeler puanlanabilir.');
    }

    if (rating < 1 || rating > 5) {
      throw const ContractWorkflowException('Puan 1 ile 5 arasında olmalıdır.');
    }

    if (review.trim().isEmpty) {
      throw const ContractWorkflowException('Yorum boş olamaz.');
    }

    final isEmployer = _isEmployer(contract, reviewerId);
    final isFreelancer = _isFreelancer(contract, reviewerId);

    if (!isEmployer && !isFreelancer) {
      throw const ContractWorkflowException('Yorum yazmaya yetkili değilsiniz.');
    }

    if (isEmployer && contract.employerRated) {
      throw const ContractWorkflowException('Zaten yorum yaptınız.');
    }

    if (isFreelancer && contract.freelancerRated) {
      throw const ContractWorkflowException('Zaten yorum yaptınız.');
    }

    await transaction.execute(
      rpc: 'submit_rating_rpc',
      params: {
        'p_contract_id': contractId,
        'p_reviewer_id': reviewerId,
        'p_rating': rating,
        'p_review': review.trim(),
      },
    );

    await eventService.ratingSubmitted(
      contractId: contractId,
      actorId: reviewerId,
      rating: rating,
    );
  }
}