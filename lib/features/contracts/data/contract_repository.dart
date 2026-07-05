import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../shared/enums/payment_status.dart';

abstract class ContractRepository {
  Future<List<ContractModel>> getAllContracts();

  Future<List<ContractModel>> getByFreelancer(String freelancerId);

  Future<List<ContractModel>> getByEmployer(String employerId);

  Future<ContractModel?> getById(String contractId);

  Future<ContractModel?> getByJobId(String jobId);

  Future<bool> hasContractForJob(String jobId);

  Future<void> addContract(ContractModel contract);

  Future<void> updateContractStatus(String contractId, ContractStatus status);
  Future<void> updatePaymentStatus(
      String contractId,
      PaymentStatus status,
      );
}