import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_exception.dart';
import '../../shared/models/contract_model.dart';
import '../../shared/enums/contract_status.dart';

abstract class IContractService {
  Future<List<ContractModel>> getMyContracts(String userId);
  Future<ContractModel> getContractDetail(String contractId);
  Future<ContractModel> createContract(ContractModel contract);
  Future<void> updateContractStatus(String contractId, ContractStatus status);
  Future<void> submitWork(String contractId);
  Future<void> approveWork(String contractId);
  Future<void> rejectWork(String contractId, String reason);
  Future<void> releasePayment(String contractId);
  Future<List<ContractModel>> getActiveContracts(String userId);
  Future<List<ContractModel>> getCompletedContracts(String userId);
}

class SupabaseContractService implements IContractService {
  final SupabaseClient _supabase;

  SupabaseContractService(this._supabase);

  @override
  Future<List<ContractModel>> getMyContracts(String userId) async {
    try {
      final response = await _supabase
          .from('contracts')
          .select()
          .or('freelancer_id.eq.$userId,employer_id.eq.$userId')
          .order('created_at', ascending: false);

      return List<ContractModel>.from(
        response.map((contract) => ContractModel.fromMap(contract)),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<ContractModel> getContractDetail(String contractId) async {
    try {
      final response = await _supabase
          .from('contracts')
          .select()
          .eq('id', contractId)
          .single();

      return ContractModel.fromMap(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<ContractModel> createContract(ContractModel contract) async {
    try {
      final contractData = contract.toInsertMap();
      contractData['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('contracts')
          .insert(contractData)
          .select()
          .single();

      return ContractModel.fromMap(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> updateContractStatus(String contractId, ContractStatus status) async {
    try {
      await _supabase
          .from('contracts')
          .update({
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', contractId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> submitWork(String contractId) async {
    try {
      await _supabase
          .from('contracts')
          .update({
        'status': ContractStatus.submitted.name,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', contractId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> approveWork(String contractId) async {
    try {
      await _supabase
          .from('contracts')
          .update({
        'status': ContractStatus.completed.name,
        'payment_status': 'released',
      })
          .eq('id', contractId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> rejectWork(String contractId, String reason) async {
    try {
      await _supabase
          .from('contracts')
          .update({
        'status': ContractStatus.revisionRequested.name,
      })
          .eq('id', contractId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> releasePayment(String contractId) async {
    try {
      await _supabase
          .from('contracts')
          .update({
        'payment_status': 'released',
      })
          .eq('id', contractId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<ContractModel>> getActiveContracts(String userId) async {
    try {
      final response = await _supabase
          .from('contracts')
          .select()
          .or('freelancer_id.eq.$userId,employer_id.eq.$userId')
          .neq('status', 'completed')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      return List<ContractModel>.from(
        response.map((contract) => ContractModel.fromMap(contract)),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<ContractModel>> getCompletedContracts(String userId) async {
    try {
      final response = await _supabase
          .from('contracts')
          .select()
          .or('freelancer_id.eq.$userId,employer_id.eq.$userId')
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      return List<ContractModel>.from(
        response.map((contract) => ContractModel.fromMap(contract)),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }
}