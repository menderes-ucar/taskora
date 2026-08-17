import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_exception.dart';
import '../../shared/models/contract_model.dart';

abstract class IContractService {
  Future<List<ContractModel>> getMyContracts(String userId);
  Future<ContractModel> getContractDetail(String contractId);
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