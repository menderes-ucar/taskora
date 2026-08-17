

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_exception.dart';
import '../../shared/models/user_model.dart';

abstract class IProfileService {
  Future<UserModel> getUserProfile(String userId);

  Future<UserModel> updateProfile(UserModel user);

  Future<List<UserModel>> searchFreelancers({
    String? skill,
    String? search,
    int page = 1,
  });

  Future<List<UserModel>> searchEmployers({
    String? search,
    int page = 1,
  });

  Future<void> uploadProfileImage(
      String userId,
      File imageFile,
      );

  Future<void> updateFreelancerProfile({
    required String userId,
    required List<String> skills,
    required String bio,
    required String hourlyRate,
  });

  Future<void> updateEmployerProfile({
    required String userId,
    required String companyName,
    required String bio,
  });
}

class SupabaseProfileService implements IProfileService {
  final SupabaseClient _supabase;

  SupabaseProfileService(this._supabase);

  @override
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('''
            *,
            freelancer_profile:freelancer_profiles(*),
            employer_profile:employer_profiles(*)
          ''')
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(
        e,
        StackTrace.current,
      );
    }
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      final userData = {
        'email': user.email,
        'name': user.name,
        'avatar_url': user.avatarUrl,
        'phone': user.phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('users')
          .update(userData)
          .eq('id', user.id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw ExceptionFactory.create(
        e,
        StackTrace.current,
      );
    }
  }

  @override
  Future<List<UserModel>> searchFreelancers({
    String? skill,
    String? search,
    int page = 1,
  }) async {
    try {
      const limit = 20;
      final offset = (page - 1) * limit;

      var query = _supabase
          .from('users')
          .select('''
      *,
      freelancer_profile:freelancer_profiles(*)
    ''')
          .eq('role', 'freelancer');

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'name.ilike.%$search%',
        );
      }

      if (skill != null && skill.isNotEmpty) {
        query = query.contains(
          'skills',
          [skill],
        );
      }

      final response = await query
          .range(offset, offset + limit - 1);

      if (skill != null && skill.isNotEmpty) {
        query = query.filter(
          'skills',
          'cs',
          '{$skill}',
        );
      }


      return List<UserModel>.from(
        (response as List).map(
              (user) => UserModel.fromJson(
            user as Map<String, dynamic>,
          ),
        ),
      );
    } catch (e) {
      throw ExceptionFactory.create(
        e,
        StackTrace.current,
      );
    }
  }

  @override
  Future<List<UserModel>> searchEmployers({
    String? search,
    int page = 1,
  }) async {
    try {
      const limit = 20;
      final offset = (page - 1) * limit;

      var query = _supabase
          .from('users')
          .select('''
      *,
      employer_profile:employer_profiles(*)
    ''')
          .eq('role', 'employer');

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'name.ilike.%$search%',
        );
      }

      final response = await query
          .range(offset, offset + limit - 1);

      return List<UserModel>.from(
        (response as List).map(
              (user) => UserModel.fromJson(
            user as Map<String, dynamic>,
          ),
        ),
      );
    } catch (e) {
      throw ExceptionFactory.create(
        e,
        StackTrace.current,
      );
    }
  }

  @override
  Future<void> uploadProfileImage(
      String userId,
      File imageFile,
      ) async {
    try {
      final filename = 'profile_$userId.jpg';

      await _supabase.storage
          .from('profiles')
          .upload(
        filename,
        imageFile,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
          cacheControl: '3600',
        ),
      );

      // Keep one stable storage object per user while versioning the URL so
      // clients do not keep displaying a cached previous avatar.
      final publicUrl = _supabase.storage
          .from('profiles')
          .getPublicUrl(filename);

      final versionedUrl =
          '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('users')
          .update({
        'avatar_url': versionedUrl,
      })
          .eq('id', userId);
    } catch (e) {
      throw ExceptionFactory.create(
        e,
        StackTrace.current,
      );
    }
  }

  @override
  Future<void> updateFreelancerProfile({
    required String userId,
    required List<String> skills,
    required String bio,
    required String hourlyRate,
  }) async {
    try {
      final existing = await _supabase
          .from('freelancer_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('freelancer_profiles')
            .update({
          'skills': skills,
          'bio': bio,
          'hourly_rate': double.parse(hourlyRate),
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', userId);
      } else {
        await _supabase
            .from('freelancer_profiles')
            .insert({
          'user_id': userId,
          'skills': skills,
          'bio': bio,
          'hourly_rate': double.parse(hourlyRate),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw ExceptionFactory.create(
        e,
        StackTrace.current,
      );
    }
  }

  @override
  Future<void> updateEmployerProfile({
    required String userId,
    required String companyName,
    required String bio,
  }) async {
    try {
      final existing = await _supabase
          .from('employer_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('employer_profiles')
            .update({
          'company_name': companyName,
          'bio': bio,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', userId);
      } else {
        await _supabase
            .from('employer_profiles')
            .insert({
          'user_id': userId,
          'company_name': companyName,
          'bio': bio,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw ExceptionFactory.create(
        e,
        StackTrace.current,
      );
    }
  }
}