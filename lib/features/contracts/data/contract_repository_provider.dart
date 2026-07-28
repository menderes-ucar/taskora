import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/enums/payment_status.dart';
import '../../../../shared/models/contract_delivery_model.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../../shared/models/contract_timeline_model.dart';

abstract class IContractRepository {
  // Liste & Arama
  Future<List<ContractModel>> getAllContracts();
  Future<List<ContractModel>> getByFreelancer(String freelancerId);
  Future<List<ContractModel>> getByEmployer(String employerId);
  Future<ContractModel?> getById(String contractId);
  Future<ContractModel?> getByJobId(String jobId);
  Future<bool> hasContractForJob(String jobId);

  // Yan Tablolar
  Future<List<ContractTimelineModel>> getTimeline(String contractId);
  Future<List<ContractDeliveryModel>> getDeliveries(String contractId);

  // Ekleme & Güncelleme
  Future<void> addContract(ContractModel contract);
  Future<void> updateContractStatus(String contractId, ContractStatus status);
  Future<void> updatePaymentStatus(String contractId, PaymentStatus status);

  // RPC İşlemleri
  Future<void> releasePayment(String contractId, String actorId);
  Future<void> submitDelivery({
    required String contractId,
    required String actorId,
    required String message,
    String? fileUrl,
  });
  Future<void> requestRevision({
    required String contractId,
    required String actorId,
    required String reason,
  });
  Future<void> executeContractPayment({
    required String contractId,
    required String employerId,
    required String freelancerId,
    required double totalAmount,
  });
}

// Eski isimlendirme kullanan yerler için alias (Tip Uyuşmazlığını Çözer)
typedef ContractRepository = IContractRepository;