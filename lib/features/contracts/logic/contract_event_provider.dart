import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/services/contract_event_service.dart';
import '../domain/services/contract_event_service_impl.dart';
import 'contract_audit_provider.dart';

final contractEventProvider = Provider<ContractEventService>((ref) {
  final auditService = ref.watch(contractAuditProvider);

  return ContractEventServiceImpl(
    auditService,
  );
});
