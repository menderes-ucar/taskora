
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/services/contract_workflow_service.dart';
import 'contract_event_provider.dart';
import 'contract_transaction_provider.dart';
import 'contracts_provider.dart';

final contractWorkflowProvider =
Provider<ContractWorkflowService>((ref) {
  final repository = ref.read(contractRepositoryProvider);
  final eventService = ref.read(contractEventProvider);
  final transaction = ref.read(contractTransactionProvider);

  return ContractWorkflowService(
    repository,
    eventService,
    transaction,
  );
});
