import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/contract_delivery_model.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../../shared/models/contract_timeline_model.dart';
import '../../../core/realtime/realtime_manager.dart';
import '../data/contract_repository.dart';
import '../data/repositories/supabase_contract_repository.dart';
import '../data/services/contract_delivery_storage_service.dart';
import '../domain/services/contract_workflow_service.dart';
import 'contract_workflow_provider.dart';

final contractSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final contractDeliveryStorageProvider = Provider<ContractDeliveryStorageService>((ref) {
  return ContractDeliveryStorageService(ref.watch(contractSupabaseClientProvider));
});

final contractRepositoryProvider = Provider<IContractRepository>((ref) {
  final supabase = ref.watch(contractSupabaseClientProvider);

  return SupabaseContractRepository(supabase);
});

class ContractsNotifier extends AsyncNotifier<List<ContractModel>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _disposed = false;
  bool _isRefreshing = false;
  bool _lifecycleRegistered = false;

  IContractRepository get _repository =>
      ref.read(contractRepositoryProvider);

  ContractWorkflowService get _workflow =>
      ref.read(contractWorkflowProvider);

  @override
  Future<List<ContractModel>> build() async {

    // AsyncNotifier.build() may run again when the provider is invalidated.
    // Never assign a late-final dependency here because the same notifier
    // instance can be rebuilt during a pull-to-refresh.
    _disposed = false;

    if (!_lifecycleRegistered) {
      _lifecycleRegistered = true;

      RealtimeManager.instance.register(_restartRealtime);

      ref.onDispose(() {
        _disposed = true;
        _subscription?.cancel();
        _subscription = null;
        RealtimeManager.instance.unregister(_restartRealtime);
        _lifecycleRegistered = false;
      });
    }

    final contracts = await _loadContracts();

    state = AsyncValue.data(contracts);

    _initRealtimeStream();

    return contracts;
  }

  Future<void> _restartRealtime() async {

    if (_disposed) return;

    _subscription?.cancel();

    _initRealtimeStream();

  }

  void _initRealtimeStream() {

    _subscription?.cancel();
    _subscription = null;

    try {

      final client = Supabase.instance.client;

      _subscription = client
          .from('contracts')
          .stream(
        primaryKey: ['id'],
      )
          .order(
        'created_at',
        ascending: false,
      )
          .listen(

            (_) async {

          if (_disposed) return;

          await refreshContracts();

        },

        onError: (error, stack) async {

          debugPrint(
            '[Contracts Realtime] $error',
          );

          await refreshContracts();

        },

      );

    } catch (e) {

      debugPrint(
        '⚠️ [Subscription Init Error]: $e',
      );

    }

  }

  Future<List<ContractModel>> _loadContracts() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      return const <ContractModel>[];
    }

    // Aktif işler hem freelancer hem employer tarafından görülebilir.
    // getAllContracts() organization_id olmadan bilinçli olarak boş döndüğü
    // için burada kullanıcının iki taraflı ilişkisini doğrudan yüklüyoruz.
    final results = await Future.wait<List<ContractModel>>([
      _repository.getByFreelancer(currentUser.id),
      _repository.getByEmployer(currentUser.id),
    ]);

    final contractsById = <String, ContractModel>{};

    for (final contracts in results) {
      for (final contract in contracts) {
        contractsById[contract.id] = contract;
      }
    }

    final contracts = contractsById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return contracts;
  }

  Future<void> refreshContracts() async {

    if (_isRefreshing) return;

    _isRefreshing = true;

    final previousState = state;

    if (previousState.hasValue) {

      state = AsyncValue<List<ContractModel>>.loading()
          .copyWithPrevious(previousState);

    } else {

      state = const AsyncValue.loading();

    }

    try {

      final contracts = await _loadContracts();

      if (_disposed) return;

      state = AsyncValue.data(contracts);

    } catch (e, s) {

      if (_disposed) return;

      state = AsyncValue.error(e, s);

    } finally {

      _isRefreshing = false;

    }

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
    return _repository.getTimeline(contractId);
  }

  Future<List<ContractDeliveryModel>> getDeliveries(String contractId) {
    return _repository.getDeliveries(contractId);
  }

  Future<void> addContract(
      ContractModel contract,
      ) async {

    await _workflow.createContract(
      contract,
    );

    await refreshContracts();

  }



  Future<void> submitDelivery({
    required String contractId,
    required String message,
    String? fileUrl,
  }) async {

    final currentUserId =
        Supabase.instance.client.auth.currentUser!.id;

    await _workflow.submitDelivery(

      contractId: contractId,

      actorId: currentUserId,

      message: message,

      fileUrl: fileUrl,

    );

    await refreshContracts();

  }

  Future<void> submitDeliveryWithFiles({
    required String contractId,
    required String message,
    String? fileUrl,
    List<DeliveryUploadFile> files = const <DeliveryUploadFile>[],
  }) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Oturum bulunamadı.');
    }

    final storage = ref.read(contractDeliveryStorageProvider);

    if (files.length > ContractDeliveryStorageService.maxFilesPerDelivery) {
      throw Exception(
        'Bir teslimatta en fazla ${ContractDeliveryStorageService.maxFilesPerDelivery} dosya ekleyebilirsiniz.',
      );
    }

    for (final file in files) {
      if (file.size > ContractDeliveryStorageService.maxFileSizeBytes) {
        throw Exception('Her dosya en fazla 50 MB olabilir: ${file.name}');
      }
    }

    final deliveryResult = await _workflow.submitDelivery(
      contractId: contractId,
      actorId: currentUserId,
      message: message,
      fileUrl: fileUrl,
    );

    if (files.isNotEmpty) {
      // submit_delivery_rpc returns the exact delivery created by the same
      // transaction. Do not re-read deliveries here; that read can be blocked
      // by delivery RLS even though the insert itself succeeded.
      final deliveryId = deliveryResult['delivery_id']?.toString();
      final version = (deliveryResult['version'] as num?)?.toInt();

      if (deliveryId == null || deliveryId.isEmpty || version == null) {
        throw Exception(
          'Teslimat oluşturuldu ancak teslimat bilgisi RPC yanıtında eksik.',
        );
      }

      final uploadedPaths = <String>[];

      try {
        for (final file in files) {
          final path = await storage.uploadFile(
            contractId: contractId,
            version: version,
            file: file,
          );
          uploadedPaths.add(path);

          await storage.attachFileMetadata(
            deliveryId: deliveryId,
            actorId: currentUserId,
            fileName: file.name,
            storagePath: path,
            mimeType: file.mimeType,
            fileSize: file.size,
          );
        }
      } catch (e) {
        // Best-effort cleanup prevents orphaned storage objects if metadata
        // insertion fails after an upload. The delivery itself remains intact.
        for (final path in uploadedPaths) {
          try {
            await Supabase.instance.client.storage
                .from(ContractDeliveryStorageService.bucket)
                .remove([path]);
          } catch (_) {}
        }
        rethrow;
      }
    }

    await refreshContracts();
  }

  Future<void> requestRevision({
    required String contractId,
    required String reason,
  }) async {

    final currentUserId =
        Supabase.instance.client.auth.currentUser!.id;

    await _workflow.requestRevision(

      contractId: contractId,

      actorId: currentUserId,

      reason: reason,

    );

    await refreshContracts();

  }

  Future<void> approveDelivery(String contractId) async {

    final currentUserId =
        Supabase.instance.client.auth.currentUser!.id;

    await _workflow.approveDelivery(

      contractId: contractId,

      actorId: currentUserId,

    );

    await refreshContracts();

  }

  // Kept for backward compatibility with existing callers.
  Future<void> approveAndReleasePayment(
      String contractId,
      ) async {
    await approveDelivery(contractId);
  }
}

final contractsProvider =
AsyncNotifierProvider<ContractsNotifier, List<ContractModel>>(
  ContractsNotifier.new,
);