import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/freelancer/notification/data/mock_notification_repository.dart';
import '../../../../features/freelancer/notification/data/notification_repository.dart';
import '../../../../features/freelancer/notification/logic/notifications_provider.dart';

import '../../../models/notification_model.dart';


final notificationRepoProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});

final notificationsProvider =
StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier(this.ref) : super([]);

  final Ref ref;

  void load(String userId) {
    final repo = ref.read(notificationRepoProvider);
    state = repo.getByUser(userId);
  }

  void add(AppNotification n) {
    final repo = ref.read(notificationRepoProvider);
    repo.add(n);
    load(n.userId);
  }

  int unread(String userId) {
    return ref.read(notificationRepoProvider).unreadCount(userId);
  }
}