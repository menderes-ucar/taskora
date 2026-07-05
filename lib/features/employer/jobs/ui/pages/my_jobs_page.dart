import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_chip.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../shared/enums/job_status.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../freelancer/jobs/ui/logic/jobs_provider.dart';
import 'create_job_page.dart';
import 'edit_job_page.dart';

class MyJobsPage extends ConsumerStatefulWidget {
  const MyJobsPage({super.key});

  @override
  ConsumerState<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends ConsumerState<MyJobsPage> {
  String? selectedCategory;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final jobsAsync = ref.watch(jobsProvider);

    return jobsAsync.when(
      data: (allJobs) {
        final myJobs = currentUser == null
            ? <JobModel>[]
            : allJobs.where((job) => job.employerId == currentUser.id).toList();

        final categories = myJobs.map((e) => e.category).toSet().toList()
          ..sort();

        final filteredJobs = myJobs.where((job) {
          final matchesCategory =
              selectedCategory == null || job.category == selectedCategory;

          final query = searchController.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              job.title.toLowerCase().contains(query) ||
              job.description.toLowerCase().contains(query) ||
              job.category.toLowerCase().contains(query);

          return matchesCategory && matchesSearch;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('İlanlarım'),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              text: 'Yeni İlan',
              icon: Icons.add,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateJobPage(),
                  ),
                );
              },
            ),
          ),
          body: myJobs.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: EmptyState(
                icon: Icons.campaign_outlined,
                title: 'Henüz ilan oluşturmadınız',
                subtitle:
                'İlk ilanınızı oluşturarak freelancerlardan teklif almaya başlayabilirsiniz.',
                action: PrimaryButton(
                  text: 'İlan Oluştur',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateJobPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          )
              : Column(
            children: [
              const _MyJobsHero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'İlan ara...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                        : null,
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final label = isAll ? 'Tümü' : categories[index - 1];
                    final selected = isAll
                        ? selectedCategory == null
                        : selectedCategory == label;

                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = isAll ? null : label;
                        });
                      },
                      labelStyle: TextStyle(
                        color:
                        selected ? AppColors.black : AppColors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor:
                      AppColors.primary.withValues(alpha: 0.18),
                      backgroundColor: AppColors.lightGrey,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredJobs.isEmpty
                    ? const Center(
                  child: Text(
                    'Filtreye uygun ilan bulunamadı.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                )
                    : GridView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    return _EmployerJobGridCard(job: job);
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Hata: $error')),
      ),
    );
  }
}

class _EmployerJobGridCard extends ConsumerWidget {
  final JobModel job;

  const _EmployerJobGridCard({required this.job});

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return AppColors.primaryDark;
      case JobStatus.inProgress:
        return AppColors.warning;
      case JobStatus.completed:
        return AppColors.success;
      case JobStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(job.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primaryDark,
                  size: 26,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditJobPage(job: job),
                        ),
                      );
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('İlan silinsin mi?'),
                          content: const Text(
                            'Bu ilanı silmek istediğinize emin misiniz?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Vazgeç'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await ref
                            .read(jobsProvider.notifier)
                            .removeJob(job.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('İlan silindi')),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Düzenle'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AppChip(
                        label: job.status.label,
                        color: statusColor.withValues(alpha: 0.18),
                        textColor: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                      AppChip(label: job.category),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '₺${job.budget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _MyJobsHero extends StatelessWidget {
  const _MyJobsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'İlanlarını buradan yönetebilirsin',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}