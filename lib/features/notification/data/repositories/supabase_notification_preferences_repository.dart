import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_preferences_model.dart';
import 'notification_preferences_repository.dart';

class SupabaseNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  final SupabaseClient _client;

  SupabaseNotificationPreferencesRepository(this._client);

  @override
  Future<NotificationPreferences> get(String userId) async {
    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      final created = await _client
          .from('notification_preferences')
          .insert({
        'user_id': userId,
        'push_enabled': true,
        'job_alerts_enabled': true,
        'job_categories': const <String>[],
      })
          .select()
          .single();
      return NotificationPreferences.fromMap(created);
    }

    return NotificationPreferences.fromMap(response);
  }

  @override
  Future<NotificationPreferences> save(
      NotificationPreferences preferences,
      ) async {
    final response = await _client
        .from('notification_preferences')
        .upsert(preferences.toMap(), onConflict: 'user_id')
        .select()
        .single();

    return NotificationPreferences.fromMap(response);
  }
}
