import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://niylanfjecrkhmywybov.supabase.co',
    anonKey: 'sb_publishable_xWu3zUCHtwniHQL-f3Xuvw_DVs14Bm-',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}