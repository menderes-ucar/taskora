import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../employer/jobs/ui/pages/create_job_page.dart';
import '../logic/jobs_provider.dart';

class MyJobsPage extends ConsumerWidget {
  const MyJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(jobsProvider);

    return jobsAsync.when(
      data: (allJobs) {
        final myJobs = currentUser == null
            ? <JobModel>[]
            : allJobs
            .where((job) => job.employerId == currentUser.id)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            title: const Text('İlanlarım'),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateJobPage(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: myJobs.isEmpty
              ? const Center(
            child: Text(
              'Henüz ilan oluşturmadınız.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: myJobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = myJobs[index];
              return _MyJobCard(job: job);
            },
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Hata: $error'),
        ),
      ),
    );
  }
}

class _MyJobCard extends StatelessWidget {
  final JobModel job;

  const _MyJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                job.category,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                '₺${job.budget.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}