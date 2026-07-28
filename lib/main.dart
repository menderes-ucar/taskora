import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'features/notification/data/services/notification_helper.dart';
import 'firebase_options.dart';

import 'app/router/app_router.dart';
import 'app/router/route_names.dart';
import 'app/theme/app_theme.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Sertifika bypass sınıfını küresel olarak aktif eden satır:
    HttpOverrides.global = MyHttpOverrides();

    try {
      // 0. Environment Dosyasını Yükle
      await dotenv.load(fileName: ".env");

      // 1. Firebase Altyapısı
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Supabase Altyapısı (.env dosyasından okur)
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      await NotificationHelper.initNotifications();

    } catch (e) {
      debugPrint(' 🚨 [SaaS Kritik Hata] Başlatma esnasında sorun oluştu: $e');
    }

    final session = Supabase.instance.client.auth.currentSession;
    final userRole = Supabase.instance.client.auth.currentUser?.userMetadata?['role']?.toString().toLowerCase();

    String targetInitialRoute = RouteNames.login;

    if (session != null) {
      if (userRole == 'employer') {
        targetInitialRoute = RouteNames.employerShell;
      } else {
        targetInitialRoute = RouteNames.freelancerShell;
      }
    }

    runApp(
      ProviderScope(
        child: TaskoraApp(initialRoute: targetInitialRoute),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint(' 🚨 [SaaS Global Asenkron Hata]: $error');
  });
}

class TaskoraApp extends ConsumerWidget {
  final String initialRoute;

  const TaskoraApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Taskora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,

      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('tr', 'TR'),
      ],
      locale: const Locale('en', 'US'),
    );
  }
}