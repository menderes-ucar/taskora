import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/enums/app_notification_type.dart';
import '../../../../shared/models/notification_model.dart';
import '../logic/notifications_provider.dart';

class NotificationHelper {
  static void send({
    required Ref ref,
    required String userId,
    required String title,
    required String body,
    required AppNotificationType type,
    String? relatedId,
  }) {
    final notification = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );

    ref.read(notificationsProvider.notifier).add(notification);
  }
}