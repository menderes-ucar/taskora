import '../../../../shared/data/mock_data.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/enums/payment_status.dart';
import '../../../../shared/models/contract_model.dart';
import 'contract_repository.dart';

class MockContractRepository implements ContractRepository {
  final List<ContractModel> _contracts =
  List<ContractModel>.from(MockData.contracts);

  @override
  Future<List<ContractModel>> getAllContracts() async {
    return List<ContractModel>.from(_contracts);
  }

  @override
  Future<List<ContractModel>> getByFreelancer(String freelancerId) async {
    return _contracts
        .where((contract) => contract.freelancerId == freelancerId)
        .toList();
  }

  @override
  Future<List<ContractModel>> getByEmployer(String employerId) async {
    return _contracts
        .where((contract) => contract.employerId == employerId)
        .toList();
  }

  @override
  Future<ContractModel?> getById(String contractId) async {
    try {
      return _contracts.firstWhere((contract) => contract.id == contractId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ContractModel?> getByJobId(String jobId) async {
    try {
      return _contracts.firstWhere((contract) => contract.jobId == jobId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasContractForJob(String jobId) async {
    return _contracts.any((contract) => contract.jobId == jobId);
  }

  @override
  Future<void> addContract(ContractModel contract) async {
    _contracts.insert(0, contract);
  }

  @override
  Future<void> updateContractStatus(
      String contractId,
      ContractStatus status,
      ) async {
    final index = _contracts.indexWhere((contract) => contract.id == contractId);
    if (index == -1) return;

    _contracts[index] = _contracts[index].copyWith(status: status);
  }

  @override
  Future<void> updatePaymentStatus(
      String contractId,
      PaymentStatus status,
      ) async {
    final index = _contracts.indexWhere((contract) => contract.id == contractId);
    if (index == -1) return;

    _contracts[index] = _contracts[index].copyWith(paymentStatus: status);
  }
}