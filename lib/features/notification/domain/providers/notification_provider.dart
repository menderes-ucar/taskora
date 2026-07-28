import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// 🚀 SAAS DİNAMİK STREAM PROVIDER: Auth durumu değiştiğinde otomatik yenilenir
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  if (userId == null || userId.isEmpty) {
    return Stream.value([]);
  }

  final supabase = Supabase.instance.client;

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((maps) => maps.map((map) => AppNotification.fromMap(map)).toList());
});

class NotificationActionNotifier {
  final _supabase = Supabase.instance.client;

  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (_) {}
  }
}

final notificationActionProvider = Provider<NotificationActionNotifier>((ref) {
  return NotificationActionNotifier();
});

// 🚀 PERFORMANS SAYAÇ PROVIDER'I
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});