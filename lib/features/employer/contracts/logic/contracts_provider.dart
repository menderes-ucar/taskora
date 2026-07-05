import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/mock_data.dart';
import '../../../../shared/enums/app_notification_type.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../freelancer/notification/services/notification_helper.dart';


class ContractsNotifier extends StateNotifier<List<ContractModel>> {
  ContractsNotifier(this.ref)
      : super(List<ContractModel>.from(MockData.contracts));

  final Ref ref;

  List<ContractModel> getByFreelancer(String freelancerId) {
    return state
        .where((contract) => contract.freelancerId == freelancerId)
        .toList();
  }

  List<ContractModel> getByEmployer(String employerId) {
    return state.where((contract) => contract.employerId == employerId).toList();
  }

  ContractModel? getById(String contractId) {
    try {
      return state.firstWhere((contract) => contract.id == contractId);
    } catch (_) {
      return null;
    }
  }

  ContractModel? getByJobId(String jobId) {
    try {
      return state.firstWhere((contract) => contract.jobId == jobId);
    } catch (_) {
      return null;
    }
  }

  bool hasContractForJob(String jobId) {
    return state.any((contract) => contract.jobId == jobId);
  }

  void addContract(ContractModel contract) {
    state = [contract, ...state];

    NotificationHelper.send(
      ref: ref,
      userId: contract.freelancerId,
      title: 'Yeni sözleşme oluşturuldu',
      body: '${contract.jobTitle} işi için sözleşme oluşturuldu.',
      type: AppNotificationType.contractCreated,
      relatedId: contract.id,
    );
  }

  void updateContractStatus(String contractId, ContractStatus status) {
    final contract = getById(contractId);
    if (contract == null) return;

    state = state.map((item) {
      if (item.id == contractId) {
        return item.copyWith(status: status);
      }
      return item;
    }).toList();

    if (status == ContractStatus.delivered) {
      NotificationHelper.send(
        ref: ref,
        userId: contract.employerId,
        title: 'İş teslim edildi',
        body: '${contract.jobTitle} işi freelancer tarafından teslim edildi.',
        type: AppNotificationType.workSubmitted,
        relatedId: contract.id,
      );
    }

    if (status == ContractStatus.completed) {
      NotificationHelper.send(
        ref: ref,
        userId: contract.freelancerId,
        title: 'Proje tamamlandı',
        body: '${contract.jobTitle} işi tamamlandı olarak işaretlendi.',
        type: AppNotificationType.contractCompleted,
        relatedId: contract.id,
      );
    }
  }

  void deliverContract(String contractId) {
    updateContractStatus(contractId, ContractStatus.delivered);
  }

  void completeContract(String contractId) {
    updateContractStatus(contractId, ContractStatus.completed);
  }
}

final contractsProvider =
StateNotifierProvider<ContractsNotifier, List<ContractModel>>((ref) {
  return ContractsNotifier(ref);
});