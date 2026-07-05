import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/notification_model.dart';
import '../data/mock_notification_repository.dart';
import '../data/notification_repository.dart';

final notificationRepoProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});

final notificationsProvider =
StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier(this.ref) : super(const []);

  final Ref ref;

  void load(String userId) {
    final repo = ref.read(notificationRepoProvider);
    state = repo.getByUser(userId);
  }

  void loadForUser(String userId) {
    load(userId);
  }

  void add(AppNotification notification) {
    final repo = ref.read(notificationRepoProvider);
    repo.add(notification);
    load(notification.userId);
  }

  int unread(String userId) {
    final repo = ref.read(notificationRepoProvider);
    return repo.unreadCount(userId);
  }

  int unreadCount(String userId) {
    return unread(userId);
  }

  void markAsRead({
    required String notificationId,
    required String userId,
  }) {
    final repo = ref.read(notificationRepoProvider);
    repo.markAsRead(notificationId);
    load(userId);
  }

  void markAllAsRead(String userId) {
    final repo = ref.read(notificationRepoProvider);
    repo.markAllAsRead(userId);
    load(userId);
  }
}