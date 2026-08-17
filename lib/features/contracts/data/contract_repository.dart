import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_delivery_model.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../../shared/models/contract_timeline_model.dart';

abstract class IContractRepository {
  Future<List<ContractModel>> getAllContracts({
    String? organizationId,
  });

  Future<List<ContractModel>> getByFreelancer(String freelancerId);

  Future<List<ContractModel>> getByEmployer(String employerId);

  Future<ContractModel?> getById(String contractId);

  Future<ContractStatus> getCurrentStatus(String contractId);

  Future<ContractModel?> getByJobId(String jobId);

  Future<bool> hasContractForJob(String jobId);

  Future<List<ContractTimelineModel>> getTimeline(String contractId);

  Future<List<ContractDeliveryModel>> getDeliveries(String contractId);
}
