import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/enums/contract_status.dart';
import '../../../../shared/models/contract_delivery_model.dart';
import '../../../../shared/models/contract_model.dart';
import '../services/contract_delivery_storage_service.dart';
import '../../../../shared/models/contract_timeline_model.dart';
import '../contract_repository.dart';

class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);

  @override
  String toString() => message;
}

class SupabaseContractRepository implements IContractRepository {
  final SupabaseClient _supabase;
  static const String _table = 'contracts';

  SupabaseContractRepository(this._supabase);

  List<Map<String, dynamic>> _decodeRows(
      dynamic response,
      String context,
      ) {
    if (response is! List) {
      throw RepositoryException(
        'Beklenmeyen veri formatı: $context (${response.runtimeType})',
      );
    }

    final rows = <Map<String, dynamic>>[];

    for (final item in response) {
      if (item is! Map) {
        throw RepositoryException(
          'Beklenmeyen satır formatı: $context (${item.runtimeType})',
        );
      }

      rows.add(Map<String, dynamic>.from(item));
    }

    return rows;
  }

  @override
  Future<List<ContractModel>> getAllContracts({
    String? organizationId,
  }) async {
    final normalizedOrganizationId = organizationId?.trim();

    if (normalizedOrganizationId == null || normalizedOrganizationId.isEmpty) {
      return const <ContractModel>[];
    }

    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('organization_id', normalizedOrganizationId)
          .order('created_at', ascending: false);

      return _decodeRows(
        response,
        'Sözleşmeler',
      ).map(ContractModel.fromMap).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException('Sözleşmeler yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Sözleşmeler yüklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<List<ContractModel>> getByFreelancer(String freelancerId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('freelancer_id', freelancerId)
          .order('created_at', ascending: false);

      return _decodeRows(
        response,
        'Freelancer sözleşmeleri',
      ).map(ContractModel.fromMap).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException('Freelancer sözleşmeleri yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Freelancer sözleşmeleri yüklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<List<ContractModel>> getByEmployer(String employerId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);

      return _decodeRows(
        response,
        'Employer sözleşmeleri',
      ).map(ContractModel.fromMap).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException('Employer sözleşmeleri yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Employer sözleşmeleri yüklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<ContractModel?> getById(String contractId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', contractId)
          .maybeSingle();

      if (response == null) return null;

      return ContractModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      throw RepositoryException('Sözleşme yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Sözleşme yüklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<ContractStatus> getCurrentStatus(String contractId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('status')
          .eq('id', contractId)
          .single();

      final statusValue = response['status'];
      if (statusValue == null) {
        throw RepositoryException('Sözleşme durumu bulunamadı');
      }

      return ContractStatusX.fromString(statusValue);
    } on PostgrestException catch (e) {
      throw RepositoryException('Sözleşme durumu yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Sözleşme durumu yüklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<ContractModel?> getByJobId(String jobId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .maybeSingle();

      if (response == null) return null;

      return ContractModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      throw RepositoryException('Job sözleşmesi yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Job sözleşmesi yüklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasContractForJob(String jobId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('id')
          .eq('job_id', jobId)
          .limit(1);

      return _decodeRows(
        response,
        'Job sözleşmesi kontrolü',
      ).isNotEmpty;
    } on PostgrestException catch (e) {
      throw RepositoryException('Job sözleşmesi kontrolü başarısız: ${e.message}');
    } catch (e) {
      throw RepositoryException('Job sözleşmesi kontrolü başarısız: ${e.toString()}');
    }
  }

  @override
  Future<List<ContractTimelineModel>> getTimeline(String contractId) async {
    try {
      final response = await _supabase
          .from('contract_timeline')
          .select()
          .eq('contract_id', contractId)
          .order('created_at', ascending: true);

      return _decodeRows(
        response,
        'Sözleşme zaman çizelgesi',
      ).map(ContractTimelineModel.fromMap).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException('Sözleşme zaman çizelgesi yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Sözleşme zaman çizelgesi yüklenemedi: ${e.toString()}');
    }
  }

  @override
  Future<List<ContractDeliveryModel>> getDeliveries(String contractId) async {
    try {
      final deliveryResponse = await _supabase
          .from('contract_deliveries')
          .select()
          .eq('contract_id', contractId)
          .order('version', ascending: false);

      final deliveryRows = _decodeRows(
        deliveryResponse,
        'Teslimler',
      );

      if (deliveryRows.isEmpty) {
        return const <ContractDeliveryModel>[];
      }

      final deliveryIds = deliveryRows
          .map((row) => row['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (deliveryIds.isEmpty) {
        return deliveryRows.map(ContractDeliveryModel.fromMap).toList();
      }

      final fileResponse = await _supabase
          .from('contract_delivery_files')
          .select()
          .inFilter('delivery_id', deliveryIds)
          .order('created_at', ascending: true);

      final fileRows = _decodeRows(
        fileResponse,
        'Teslimat dosyaları',
      );

      final filesByDelivery = <String, List<Map<String, dynamic>>>{};
      for (final file in fileRows) {
        final deliveryId = file['delivery_id']?.toString();
        if (deliveryId == null || deliveryId.isEmpty) continue;
        filesByDelivery.putIfAbsent(deliveryId, () => []).add(file);
      }

      final storage = ContractDeliveryStorageService(_supabase);
      final models = <ContractDeliveryModel>[];

      for (final row in deliveryRows) {
        final deliveryId = row['id']?.toString() ?? '';
        final files = filesByDelivery[deliveryId] ?? const [];
        final resolvedFiles = <Map<String, dynamic>>[];

        for (final file in files) {
          final copy = Map<String, dynamic>.from(file);
          final rawUrl = copy['file_url']?.toString() ?? '';
          if (rawUrl.startsWith('storage://')) {
            final storagePath = rawUrl.substring('storage://'.length);
            try {
              copy['file_url'] = await storage.createSignedUrl(storagePath);
            } catch (_) {
              // Keep the storage reference if a signed URL cannot be created.
              // The delivery card will show it as unavailable instead of failing
              // the complete delivery history.
            }
          }
          resolvedFiles.add(copy);
        }

        final deliveryMap = Map<String, dynamic>.from(row);
        deliveryMap['contract_delivery_files'] = resolvedFiles;
        models.add(ContractDeliveryModel.fromMap(deliveryMap));
      }

      return models;
    } on PostgrestException catch (e) {
      throw RepositoryException('Teslimler yüklenemedi: ${e.message}');
    } catch (e) {
      throw RepositoryException('Teslimler yüklenemedi: ${e.toString()}');
    }
  }






}
