import '../../../../shared/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getByUser(String userId);
  Future<void> add(AppNotification notification);
  Future<int> unreadCount(String userId);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead(String userId);
}