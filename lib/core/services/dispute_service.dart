// lib/core/services/dispute_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_exception.dart';
import 'dart:io';

class DisputeModel {
  final String id;
  final String contractId;
  final String raisedBy;
  final String? reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolution;

  DisputeModel({
    required this.id,
    required this.contractId,
    required this.raisedBy,
    this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) => DisputeModel(
    id: json['id'],
    contractId: json['contract_id'],
    raisedBy: json['raised_by'],
    reason: json['reason'],
    description: json['description'],
    status: json['status'],
    createdAt: DateTime.parse(json['created_at']),
    resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
    resolution: json['resolution'],
  );
}

abstract class IDisputeService {
  Future<List<DisputeModel>> getMyDisputes(String userId);
  Future<DisputeModel> getDisputeDetail(String disputeId);
  Future<DisputeModel> raiseDispute({
    required String contractId,
    required String reason,
    required String description,
  });
  Future<void> addDisputeEvidence(
      String disputeId,
      File file,
      );
  Future<void> resolveDispute(String disputeId, String resolution);
  Future<void> closeDispute(String disputeId);
  Future<List<Map<String, dynamic>>> getDisputeConversation(String disputeId);
}

class SupabaseDisputeService implements IDisputeService {
  final SupabaseClient _supabase;

  SupabaseDisputeService(this._supabase);

  @override
  Future<List<DisputeModel>> getMyDisputes(String userId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select()
          .eq('raised_by', userId)
          .order('created_at', ascending: false);

      return List<DisputeModel>.from(
        response.map((dispute) => DisputeModel.fromJson(dispute)),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<DisputeModel> getDisputeDetail(String disputeId) async {
    try {
      final response = await _supabase
          .from('disputes')
          .select()
          .eq('id', disputeId)
          .single();

      return DisputeModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<DisputeModel> raiseDispute({
    required String contractId,
    required String reason,
    required String description,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw AppException(
        message: 'Kullanıcı oturumu bulunamadı.',
        type: AppExceptionType.authentication,
      );
    }

    if (reason.trim().length < 5) {
      throw AppException(
        message: 'Uyuşmazlık nedeni en az 5 karakter olmalıdır.',
        type: AppExceptionType.validation,
      );
    }

    try {
      final result = await _supabase.rpc(
        'open_dispute_secure',
        params: {
          'p_contract_id': contractId,
          'p_reason': reason.trim(),
          'p_description': description.trim(),
        },
      );

      final disputeId = (result as Map<String, dynamic>?)?['dispute_id']?.toString();
      if (disputeId == null || disputeId.isEmpty) {
        throw AppException(
          message: 'Dispute oluşturulamadı.',
          type: AppExceptionType.serverError,
        );
      }

      return getDisputeDetail(disputeId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> addDisputeEvidence(
      String disputeId,
      File file,
      ) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AppException(
          message: 'Kullanıcı oturumu bulunamadı.',
          type: AppExceptionType.authentication,
        );
      }

      final filename =
          '$currentUserId/disputes/$disputeId/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'evidence'}';

      await _supabase.storage.from('disputes').upload(
        filename,
        file,
        fileOptions: const FileOptions(upsert: false),
      );

      final fileUrl = _supabase.storage.from('disputes').getPublicUrl(filename);

      await _supabase.rpc(
        'add_dispute_evidence_secure',
        params: {
          'p_dispute_id': disputeId,
          'p_file_url': fileUrl,
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> resolveDispute(String disputeId, String resolution) async {
    try {
      if (resolution.trim().isEmpty) {
        throw AppException(
          message: 'Çözüm türü boş olamaz.',
          type: AppExceptionType.validation,
        );
      }

      await _supabase.rpc(
        'admin_resolve_dispute_secure',
        params: {
          'p_dispute_id': disputeId,
          'p_resolution': resolution.trim(),
          'p_freelancer_amount': 0,
          'p_refund_amount': 0,
          'p_note': '',
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> closeDispute(String disputeId) async {
    try {
      await _supabase.rpc(
        'admin_close_dispute_secure',
        params: {
          'p_dispute_id': disputeId,
        },
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDisputeConversation(String disputeId) async {
    try {
      final response = await _supabase
          .from('dispute_messages')
          .select()
          .eq('dispute_id', disputeId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }
}
