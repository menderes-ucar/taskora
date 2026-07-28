import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../admin_guard.dart';


class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(title: const Text("Şikayet Yönetimi")),
        body: StreamBuilder(
          stream: Supabase.instance.client.from('reports').stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final reports = snapshot.data!;
            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(reports[i]['reason'], style: const TextStyle(color: Colors.white)),
                subtitle: Text(reports[i]['description'], style: const TextStyle(color: AppColors.grey)),
              ),
            );
          },
        ),
      ),
    );
  }
}