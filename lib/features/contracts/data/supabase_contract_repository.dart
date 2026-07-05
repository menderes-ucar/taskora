import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_model.dart';
import '../../../shared/enums/payment_status.dart';
import 'contract_repository.dart';

class SupabaseContractRepository implements ContractRepository {
  final SupabaseClient _supabase;

  SupabaseContractRepository(this._supabase);

  static const String _table = 'contracts';

  @override
  Future<List<ContractModel>> getAllContracts() async {
    final response = await _supabase
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ContractModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<ContractModel>> getByFreelancer(String freelancerId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('freelancer_id', freelancerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ContractModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<ContractModel>> getByEmployer(String employerId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('employer_id', employerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => ContractModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
  @override
  Future<void> updatePaymentStatus(
      String contractId,
      PaymentStatus status,
      ) async {
    await _supabase.from(_table).update({
      'payment_status': status.name,
    }).eq('id', contractId);
  }
  @override
  Future<ContractModel?> getById(String contractId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('id', contractId)
        .maybeSingle();

    if (response == null) return null;

    return ContractModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<ContractModel?> getByJobId(String jobId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('job_id', jobId)
        .maybeSingle();

    if (response == null) return null;

    return ContractModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<bool> hasContractForJob(String jobId) async {
    final response = await _supabase
        .from(_table)
        .select('id')
        .eq('job_id', jobId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  @override
  Future<void> addContract(ContractModel contract) async {
    await _supabase.from(_table).insert(contract.toInsertMap());
  }

  @override
  Future<void> updateContractStatus(
      String contractId,
      ContractStatus status,
      ) async {
    await _supabase.from(_table).update({
      'status': status.name,
    }).eq('id', contractId);
  }
}