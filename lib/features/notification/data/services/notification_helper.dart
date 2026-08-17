import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [FCM Background]: ${message.messageId}');
}

class NotificationHelper {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static bool _initialized = false;

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    'taskora_notifications',
    'Taskora Bildirimleri',
    description: 'Önemli Taskora uygulama bildirimleri',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initNotifications() async {
    if (_initialized) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ Bildirim izni reddedildi.');
        return;
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // iOS foreground presentation is handled by FCM/APNs.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      await _tokenSubscription?.cancel();
      _tokenSubscription = _fcm.onTokenRefresh.listen(
        _updateTokenInSupabase,
      );

      _initialized = true;

      // If the user is already authenticated, persist the current token.
      await saveFcmToken();

      debugPrint('✅ Notification infrastructure initialized.');
    } catch (e, stack) {
      debugPrint('🚨 Notification initialization failed: $e\n$stack');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Android does not automatically show a notification while the app is
    // foregrounded, so render it through the local notification plugin.
    // On iOS FCM/APNs foreground presentation is already enabled above;
    // showing a second local notification would create a duplicate.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final android = notification.android;

    await _localNotifications.show(
      message.messageId?.hashCode ?? notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: message.data['related_id']?.toString(),
    );
  }

  static Future<void> saveFcmToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint(
            'ℹ️ APNs token henüz hazır değil; FCM token daha sonra kaydedilecek.',
          );
          return;
        }
      }

      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      await _updateTokenInSupabase(token);
    } catch (e) {
      debugPrint('🚨 FCM token kaydedilemedi: $e');
    }
  }

  static Future<void> _updateTokenInSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || token.isEmpty) return;

    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      await Supabase.instance.client.from('user_push_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );

      // Keep the legacy profile token populated during migration. The
      // server prefers user_push_tokens and falls back to this field.
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);

      debugPrint('✅ FCM token $platform cihazı için kaydedildi.');
    } catch (e) {
      debugPrint('🚨 Supabase FCM token update hatası: $e');
    }
  }

  static Future<void> clearCurrentDeviceToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await Supabase.instance.client
            .from('user_push_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('token', token);
      }
    } catch (e) {
      debugPrint('⚠️ Cihaz FCM token kaydı silinemedi: $e');
    }
  }

  static Future<void> send({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    await sendNotification(
      targetUserId: targetUserId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
    );
  }

  /// Persists the in-app notification. FCM delivery is handled server-side
  /// by the Supabase Database Webhook -> send-fcm Edge Function pipeline.
  /// Keeping push delivery out of the client prevents users from forging push
  /// requests to arbitrary accounts.
  static Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    if (targetUserId.isEmpty) return;

    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': targetUserId,
        'title': title,
        'body': body,
        'type': type,
        'related_id': relatedId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // FCM is intentionally not invoked from the client. A Supabase
      // AFTER INSERT webhook on public.notifications calls send-fcm.
    } catch (e) {
      debugPrint('🚨 In-app bildirim oluşturulamadı: $e');
    }
  }

}
