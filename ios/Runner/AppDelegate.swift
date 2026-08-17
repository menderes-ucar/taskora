import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase is initialized from Flutter with DefaultFirebaseOptions.
    // Do not call FirebaseApp.configure() here to avoid double initialization.
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    Messaging.messaging().delegate = self

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ APNs registration failed: \(error)")
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    guard let fcmToken, !fcmToken.isEmpty else { return }
    print("✅ FCM registration token refreshed.")
    // The Flutter NotificationHelper persists the token to Supabase.
  }
}
