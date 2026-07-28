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
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw AppException(
          message: 'Kullanıcı oturumu bulunamadı.',
          type: AppExceptionType.authentication,
        );
      }
      final existing = await _supabase
          .from('disputes')
          .select()
          .eq('contract_id', contractId)
          .eq('status', 'open')
          .maybeSingle();

      if (existing != null) {
        throw AppException(
          message: 'A dispute is already open for this contract',
          type: AppExceptionType.validation,
        );
      }

      final response = await _supabase
          .from('disputes')
          .insert({
        'contract_id': contractId,
        'raised_by': currentUserId,
        'reason': reason,
        'description': description,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      return DisputeModel.fromJson(response);
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
      final filename =
          'dispute_${disputeId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await _supabase.storage
          .from('disputes')
          .upload(
        filename,
        file,
        fileOptions: const FileOptions(
          upsert: true,
        ),
      );

      final fileUrl = _supabase.storage
          .from('disputes')
          .getPublicUrl(filename);

      await _supabase.from('dispute_evidence').insert({
        'dispute_id': disputeId,
        'file_url': fileUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> resolveDispute(String disputeId, String resolution) async {
    try {
      await _supabase
          .from('disputes')
          .update({
        'status': 'resolved',
        'resolution': resolution,
        'resolved_at': DateTime.now().toIso8601String(),
      })
          .eq('id', disputeId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> closeDispute(String disputeId) async {
    try {
      await _supabase
          .from('disputes')
          .update({'status': 'closed'})
          .eq('id', disputeId);
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
