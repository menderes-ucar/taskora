import '../enums/app_notification_type.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final AppNotificationType type;
  final String? relatedId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.relatedId,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    AppNotificationType? type,
    String? relatedId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}