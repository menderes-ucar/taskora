import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Uygulama doğrudan LoginPage ile başlar
      initialRoute: '/',
      onGenerateRoute: AppRouter.onGenerateRoute,

      // 🚀 KIRMIZI EKRAN ENGELLEYİCİ: Tüm çekirdek lokalizasyon delegeleri buraya çakıldı
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