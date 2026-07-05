
import '../../models/notification_model.dart';

abstract class NotificationRepository {
  List<AppNotification> getByUser(String userId);
  void add(AppNotification notification);
  int unreadCount(String userId);
  void markAsRead(String id);
}