import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/notification_model.dart';
import 'notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _table = 'notifications';

  @override
  Future<List<AppNotification>> getByUser(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => AppNotification.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> add(AppNotification notification) async {
    try {
      await _client.from(_table).insert(notification.toMap());
    } catch (_) {}
  }

  @override
  Future<int> unreadCount(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _client.from(_table).update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client.from(_table).update({'is_read': true}).eq('user_id', userId);
    } catch (_) {}
  }
}