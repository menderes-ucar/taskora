import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🚀 Arka Plan FCM Mesaj İşleyicisi
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [FCM Arka Plan Bildirimi]: ${message.messageId}');
}

class NotificationHelper {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    'taskora_high_importance_channel',
    'Taskora Bildirimleri',
    description: 'Önemli Taskora uygulama bildirimleri',
    importance: Importance.max,
    playSound: true,
  );

  /// 🚀 Bildirim Altyapısını Başlatan Ana Metod
  static Future<void> initNotifications() async {
    try {
      // 1. Arka Plan İşleyicisini Bağla
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. İzin İsteme (iOS & Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ Bildirim izni kullanıcı tarafından reddedildi.');
        return;
      }

      // 3. Yerel Bildirimleri Kur
      const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      // Android Yüksek Öncelikli Bildirim Kanalını Oluştur
      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // iOS İçin Ön Plan Gösterim Seçenekleri
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Ön Planda Bildirim Geldiğinde Çalışacak Dinleyici
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && !kIsWeb) {
          _localNotifications.show(
            notification.hashCode,
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
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      // 5. Cihaz Token'ını Kaydet ve Yenilenmeyi Dinle
      await saveFcmToken();
      _fcm.onTokenRefresh.listen((newToken) async {
        await _updateTokenInSupabase(newToken);
      });
    } catch (e) {
      debugPrint('🚨 [NotificationHelper] Kurulum hatası: $e');
    }
  }

  /// 🚀 Mevcut Cihaz FCM Token'ını Supabase Profiles Tablosuna Yazar
  static Future<void> saveFcmToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ FCM Token kaydedilemedi: Oturum açmış kullanıcı yok.');
        return;
      }

      final token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenInSupabase(token);
      }
    } catch (e) {
      debugPrint('🚨 FCM Token kaydedilemedi: $e');
    }
  }

  static Future<void> _updateTokenInSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      debugPrint('✅ FCM Token Supabase profilinde güncellendi.');
    } catch (e) {
      debugPrint('🚨 Supabase FCM Token güncelleme hatası: $e');
    }
  }

  /// proposals_provider.dart ve diğer servisler için alias metod
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

  /// 🚀 Uygulama İçi Bildirim Gönderme Yardımcısı
  static Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    if (targetUserId.isEmpty) {
      debugPrint('⚠️ targetUserId boş olduğu için bildirim atlanıyor.');
      return;
    }

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
      debugPrint('✅ Bildirim veritabanına yazıldı: User -> $targetUserId');
    } catch (e) {
      debugPrint('🚨 Bildirim veritabanına eklenemedi: $e');
    }
  }
}