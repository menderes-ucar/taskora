import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/services/contract_audit_service.dart';

final contractAuditProvider = Provider<ContractAuditService>((ref) {
  final supabase = Supabase.instance.client;

  return ContractAuditService(
    supabase,
  );
});
