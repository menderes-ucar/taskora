import '../models/notification_preferences_model.dart';

abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> get(String userId);
  Future<NotificationPreferences> save(NotificationPreferences preferences);
}
