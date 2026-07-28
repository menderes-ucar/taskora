import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/enums/payment_status.dart';
import '../../../../shared/models/contract_delivery_model.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../../shared/models/contract_timeline_model.dart';
import '../data/contract_repository.dart';
import '../data/repositories/supabase_contract_repository.dart';

final contractSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final contractRepositoryProvider = Provider<IContractRepository>((ref) {
  final supabase = ref.watch(contractSupabaseClientProvider);
  return SupabaseContractRepository(supabase);
});

class ContractsNotifier extends AsyncNotifier<List<ContractModel>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<List<ContractModel>> build() async {
    _initRealtimeStream();
    return _loadContracts();
  }

  void _initRealtimeStream() {
    _subscription?.cancel();
    try {
      final client = Supabase.instance.client;

      _subscription = client
          .from('contracts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
            (data) {
          final contracts =
          data.map((map) => ContractModel.fromMap(map)).toList();
          state = AsyncValue.data(contracts);
        },
        onError: (error, stack) {
          debugPrint('⚠️ [Realtime Contracts Error]: $error');
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Subscription Init Error]: $e');
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  Future<List<ContractModel>> _loadContracts() async {
    final repository = ref.read(contractRepositoryProvider);
    return repository.getAllContracts();
  }

  Future<void> refreshContracts() async {
    state = const AsyncValue.loading();
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

  Future<List<ContractTimelineModel>> getTimeline(String contractId) {
    return ref.read(contractRepositoryProvider).getTimeline(contractId);
  }

  Future<List<ContractDeliveryModel>> getDeliveries(String contractId) {
    return ref.read(contractRepositoryProvider).getDeliveries(contractId);
  }

  Future<void> addContract(ContractModel contract) async {
    await ref.read(contractRepositoryProvider).addContract(contract);
    await refreshContracts();
  }

  Future<void> updateContractStatus(String contractId, ContractStatus status) async {
    await ref.read(contractRepositoryProvider).updateContractStatus(contractId, status);
    await refreshContracts();
  }

  Future<void> updatePaymentStatus(String contractId, PaymentStatus status) async {
    await ref.read(contractRepositoryProvider).updatePaymentStatus(contractId, status);
    await refreshContracts();
  }

  Future<void> submitDelivery({
    required String contractId,
    required String message,
    String? fileUrl,
  }) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    await ref.read(contractRepositoryProvider).submitDelivery(
      contractId: contractId,
      actorId: currentUserId,
      message: message,
      fileUrl: fileUrl,
    );
    await refreshContracts();
  }

  Future<void> requestRevision({
    required String contractId,
    required String reason,
  }) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    await ref.read(contractRepositoryProvider).requestRevision(
      contractId: contractId,
      actorId: currentUserId,
      reason: reason,
    );
    await refreshContracts();
  }

  Future<void> approveAndReleasePayment(String contractId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    await ref.read(contractRepositoryProvider).releasePayment(contractId, currentUserId);
    await refreshContracts();
  }
}

final contractsProvider =
AsyncNotifierProvider<ContractsNotifier, List<ContractModel>>(
  ContractsNotifier.new,
);