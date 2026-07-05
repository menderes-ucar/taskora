import '../../../../shared/models/notification_model.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<AppNotification> _items = [];

  @override
  List<AppNotification> getByUser(String userId) {
    final list = _items.where((e) => e.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  void add(AppNotification notification) {
    _items.insert(0, notification);
  }

  @override
  int unreadCount(String userId) {
    return _items.where((e) => e.userId == userId && !e.isRead).length;
  }

  @override
  void markAsRead(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(isRead: true);
  }

  @override
  void markAllAsRead(String userId) {
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.userId == userId && !item.isRead) {
        _items[i] = item.copyWith(isRead: true);
      }
    }
  }
}