import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/realtime/realtime_manager.dart';
import 'features/notification/data/services/notification_helper.dart';
import 'features/admin/admin_guard.dart';
import 'features/admin/dashboard/ui/pages/admin_dashboard_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/employer/ui/pages/employer_main_shell.dart';
import 'features/freelancer/ui/pages/freelancer_main_shell.dart';
import 'shared/enums/user_role.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (supabaseUrl == null || supabaseUrl.isEmpty ||
          supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
        throw StateError('Supabase environment variables are missing.');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      final stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      if (stripePublishableKey == null || stripePublishableKey.isEmpty) {
        throw StateError('STRIPE_PUBLISHABLE_KEY is missing.');
      }
      Stripe.publishableKey = stripePublishableKey;
      Stripe.merchantIdentifier = 'Taskora';
      Stripe.urlScheme = 'taskora';
      await Stripe.instance.applySettings();

      RealtimeManager.instance.initialize();
      await NotificationHelper.initNotifications();
    } catch (error, stack) {
      debugPrint('Taskora bootstrap failed: $error\n$stack');
    }

    runApp(const ProviderScope(child: TaskoraApp()));
  }, (Object error, StackTrace stack) {
    debugPrint('Taskora uncaught error: $error\n$stack');
  });
}

class TaskoraApp extends ConsumerWidget {
  const TaskoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Taskora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
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

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn || auth.user == null) {
      return const LoginPage();
    }

    switch (auth.user!.role) {
      case UserRole.admin:
      case UserRole.superAdmin:
        return const AdminGuard(child: AdminDashboardPage());
      case UserRole.employer:
        return const EmployerMainShell();
      case UserRole.freelancer:
        return const FreelancerMainShell();
    }
  }
}
