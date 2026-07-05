import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/enums/app_notification_type.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../shared/enums/payment_status.dart';
import '../../freelancer/notification/services/notification_helper.dart';
import '../data/contract_repository_provider.dart';

class ContractsNotifier extends AsyncNotifier<List<ContractModel>> {
  @override
  Future<List<ContractModel>> build() async {
    return _loadContracts();
  }

  Future<List<ContractModel>> _loadContracts() async {
    final repository = ref.read(contractRepositoryProvider);
    return repository.getAllContracts();
  }

  Future<void> refreshContracts() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => _loadContracts());
  }

  ContractModel? getById(String contractId) {
    final contracts = state.valueOrNull ?? [];
    try {
      return contracts.firstWhere((contract) => contract.id == contractId);
    } catch (_) {
      return null;
    }
  }

  ContractModel? getByJobId(String jobId) {
    final contracts = state.valueOrNull ?? [];
    try {
      return contracts.firstWhere((contract) => contract.jobId == jobId);
    } catch (_) {
      return null;
    }
  }

  List<ContractModel> getByFreelancer(String freelancerId) {
    final contracts = state.valueOrNull ?? [];
    return contracts
        .where((contract) => contract.freelancerId == freelancerId)
        .toList();
  }

  List<ContractModel> getByEmployer(String employerId) {
    final contracts = state.valueOrNull ?? [];
    return contracts
        .where((contract) => contract.employerId == employerId)
        .toList();
  }

  bool hasContractForJob(String jobId) {
    final contracts = state.valueOrNull ?? [];
    return contracts.any((contract) => contract.jobId == jobId);
  }

  Future<void> addContract(ContractModel contract) async {
    final repository = ref.read(contractRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.addContract(contract);
      return _loadContracts();
    });

    NotificationHelper.send(
      ref: ref,
      userId: contract.freelancerId,
      title: 'Yeni sözleşme oluşturuldu',
      body: '${contract.jobTitle} işi için sözleşme oluşturuldu.',
      type: AppNotificationType.contractCreated,
      relatedId: contract.id,
    );
  }

  Future<void> updateContractStatus(
      String contractId,
      ContractStatus status,
      ) async {
    final repository = ref.read(contractRepositoryProvider);
    final contract = getById(contractId);

    state = await AsyncValue.guard(() async {
      await repository.updateContractStatus(contractId, status);
      return _loadContracts();
    });

    if (contract == null) return;

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
  Future<void> fundContract(String contractId) async {
    final repository = ref.read(contractRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.updatePaymentStatus(contractId, PaymentStatus.funded);
      return _loadContracts();
    });
  }

  Future<void> releasePayment(String contractId) async {
    final repository = ref.read(contractRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.updatePaymentStatus(contractId, PaymentStatus.released);
      return _loadContracts();
    });
  }
  Future<void> deliverContract(String contractId) async {
    await updateContractStatus(contractId, ContractStatus.delivered);
  }

  Future<void> completeContract(String contractId) async {
    await updateContractStatus(contractId, ContractStatus.completed);
  }
}

final contractsProvider =
AsyncNotifierProvider<ContractsNotifier, List<ContractModel>>(
  ContractsNotifier.new,
);