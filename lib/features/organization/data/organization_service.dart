import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/organization_invitation_model.dart';
import '../../../shared/models/organization_member_model.adrt.dart';


class OrganizationService {
  final SupabaseClient _supabase;

  OrganizationService([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;


  Future<List<Map<String, dynamic>>> getMyOrganizations() async {
    final response = await _supabase.rpc('get_my_organizations');
    if (response is! List) return const [];

    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<void> switchActiveOrganization(String organizationId) async {
    final id = organizationId.trim();
    if (id.isEmpty) {
      throw PostgrestException(message: 'Geçersiz organizasyon.');
    }

    await _supabase.rpc(
      'switch_active_organization',
      params: {'p_organization_id': id},
    );
  }

  Future<String?> getCurrentOrganizationId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select('organization_id')
        .eq('id', userId)
        .maybeSingle();

    return profile?['organization_id']?.toString();
  }

  Future<Map<String, dynamic>?> getCurrentOrganization() async {
    final organizationId = await getCurrentOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return null;

    final result = await _supabase
        .from('organizations')
        .select('id, name, slug, plan, status, owner_id, created_at, updated_at')
        .eq('id', organizationId)
        .maybeSingle();

    return result == null ? null : Map<String, dynamic>.from(result);
  }

  Future<String> getCurrentOrganizationRole() async {
    final organizationId = await getCurrentOrganizationId();
    final userId = _supabase.auth.currentUser?.id;

    if (organizationId == null || userId == null) return 'none';

    final result = await _supabase
        .from('organization_members')
        .select('role')
        .eq('organization_id', organizationId)
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    return result?['role']?.toString() ?? 'none';
  }

  Future<List<OrganizationMemberModel>> getMembers() async {
    final organizationId = await getCurrentOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return const [];

    final response = await _supabase
        .from('organization_members')
        .select('user_id, role, status, joined_at, profiles(name, email, avatar_url)')
        .eq('organization_id', organizationId)
        .order('joined_at', ascending: true);

    return (response as List)
        .map((item) => OrganizationMemberModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<OrganizationInvitationModel>> getInvitations() async {
    final organizationId = await getCurrentOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return const [];

    final response = await _supabase
        .from('organization_invitations')
        .select('id, email, role, status, expires_at, created_at')
        .eq('organization_id', organizationId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => OrganizationInvitationModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<({String invitationId, String token, DateTime expiresAt})> inviteMember({
    required String email,
    required String role,
  }) async {
    final organizationId = await getCurrentOrganizationId();
    if (organizationId == null || organizationId.isEmpty) {
      throw PostgrestException(message: 'Bir organizasyona bağlı değilsiniz.');
    }

    final response = await _supabase.rpc(
      'create_organization_invitation',
      params: {
        'p_organization_id': organizationId,
        'p_email': email.trim().toLowerCase(),
        'p_role': role,
      },
    );

    final rows = response is List ? response : [response];
    if (rows.isEmpty || rows.first == null) {
      throw PostgrestException(message: 'Davet oluşturulamadı.');
    }

    final row = Map<String, dynamic>.from(rows.first as Map);
    final token = row['invitation_token']?.toString();
    final id = row['invitation_id']?.toString();
    final expires = DateTime.tryParse(row['expires_at']?.toString() ?? '');

    if (token == null || token.isEmpty || id == null || id.isEmpty || expires == null) {
      throw PostgrestException(message: 'Sunucudan geçersiz davet yanıtı alındı.');
    }

    return (invitationId: id, token: token, expiresAt: expires);
  }

  Future<void> revokeInvitation(String invitationId) async {
    await _supabase.rpc(
      'revoke_organization_invitation',
      params: {'p_invitation_id': invitationId},
    );
  }

  Future<String> acceptInvitation(String token) async {
    final result = await _supabase.rpc(
      'accept_organization_invitation',
      params: {'p_invitation_token': token.trim()},
    );

    final organizationId = result?.toString();
    if (organizationId == null || organizationId.isEmpty) {
      throw PostgrestException(message: 'Davet kabul edilemedi.');
    }

    return organizationId;
  }

  Future<void> updateMemberRole({
    required String userId,
    required String role,
  }) async {
    await _supabase.rpc(
      'update_organization_member_role',
      params: {'p_user_id': userId, 'p_role': role},
    );
  }

  Future<void> removeMember(String userId) async {
    await _supabase.rpc(
      'remove_organization_member',
      params: {'p_user_id': userId},
    );
  }

  Future<void> transferOwnership(String userId) async {
    await _supabase.rpc(
      'transfer_organization_ownership',
      params: {'p_new_owner_id': userId},
    );
  }

  Future<void> leaveOrganization() async {
    await _supabase.rpc('leave_organization');
  }
}
