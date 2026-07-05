import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskora/shared/enums/job_status.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../shared/models/job_model.dart';
import '../../../../freelancer/jobs/ui/logic/jobs_filter_provider.dart';
import '../../../../freelancer/jobs/ui/pages/job_detail_page.dart';

class JobsListPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? pageTitle;

  const JobsListPage({
    super.key,
    this.initialCategory,
    this.pageTitle,
  });

  @override
  ConsumerState<JobsListPage> createState() => _JobsListPageState();
}

class _JobsListPageState extends ConsumerState<JobsListPage> {
  late final TextEditingController _searchController;
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  bool _categoryInitialized = false;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(jobsFilterProvider);
    _searchController = TextEditingController(text: filter.searchQuery);
    _minBudgetController.text =
    filter.minBudget == null ? '' : filter.minBudget!.toStringAsFixed(0);
    _maxBudgetController.text =
    filter.maxBudget == null ? '' : filter.maxBudget!.toStringAsFixed(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoryInitialized) {
      _categoryInitialized = true;
      if (widget.initialCategory != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(jobsFilterProvider.notifier)
              .setCategory(widget.initialCategory);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    final categoriesAsync = ref.read(jobCategoriesProvider);
    final currentFilter = ref.read(jobsFilterProvider);

    categoriesAsync.whenData((categories) {
      String? selectedCategory = currentFilter.selectedCategory;
      bool onlyOpenJobs = currentFilter.onlyOpenJobs;

      _minBudgetController.text = currentFilter.minBudget == null
          ? ''
          : currentFilter.minBudget!.toStringAsFixed(0);
      _maxBudgetController.text = currentFilter.maxBudget == null
          ? ''
          : currentFilter.maxBudget!.toStringAsFixed(0);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: SizedBox(
                          width: 44,
                          child: Divider(
                            thickness: 4,
                            color: AppColors.border,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Filtrele',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'Tümü',
                            selected: selectedCategory == null,
                            onTap: () {
                              setModalState(() {
                                selectedCategory = null;
                              });
                            },
                          ),
                          ...categories.map(
                                (category) => _FilterChip(
                              label: category,
                              selected: selectedCategory == category,
                              onTap: () {
                                setModalState(() {
                                  selectedCategory = category;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Bütçe Aralığı',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minBudgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Min bütçe',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxBudgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Max bütçe',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SwitchListTile(
                        value: onlyOpenJobs,
                        onChanged: (value) {
                          setModalState(() {
                            onlyOpenJobs = value;
                          });
                        },
                        activeColor: AppColors.primaryDark,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Sadece açık ilanlar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(jobsFilterProvider.notifier).clearAll();
                                _searchController.clear();
                                _minBudgetController.clear();
                                _maxBudgetController.clear();
                                Navigator.pop(context);
                              },
                              child: const Text('Temizle'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final minBudget = double.tryParse(
                                  _minBudgetController.text.trim(),
                                );
                                final maxBudget = double.tryParse(
                                  _maxBudgetController.text.trim(),
                                );

                                ref
                                    .read(jobsFilterProvider.notifier)
                                    .setCategory(selectedCategory);
                                ref
                                    .read(jobsFilterProvider.notifier)
                                    .setMinBudget(minBudget);
                                ref
                                    .read(jobsFilterProvider.notifier)
                                    .setMaxBudget(maxBudget);
                                ref
                                    .read(jobsFilterProvider.notifier)
                                    .setOnlyOpenJobs(onlyOpenJobs);

                                Navigator.pop(context);
                              },
                              child: const Text('Uygula'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  bool _hasActiveFilters(JobsFilterState filter) {
    return filter.selectedCategory != null ||
        filter.minBudget != null ||
        filter.maxBudget != null ||
        !filter.onlyOpenJobs;
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(filteredJobsProvider);
    final filter = ref.watch(jobsFilterProvider);
    final hasCategory = widget.initialCategory != null;

    return jobsAsync.when(
      data: (jobs) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(widget.pageTitle ?? 'İş İlanları'),
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: Container(
            decoration: const BoxDecoration(),
            child: SafeArea(
              child: Column(
                children: [
                  if (hasCategory)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pageTitle ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${jobs.length} aktif ilan',
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                ref
                                    .read(jobsFilterProvider.notifier)
                                    .setSearchQuery(value);
                              },
                              decoration: const InputDecoration(
                                hintText: 'İş ara...',
                                prefixIcon: Icon(Icons.search_rounded),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _openFilterSheet,
                          child: Ink(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasActiveFilters(filter))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (filter.selectedCategory != null)
                              _ActiveFilterChip(
                                label: filter.selectedCategory!,
                                onRemove: () {
                                  ref
                                      .read(jobsFilterProvider.notifier)
                                      .setCategory(null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: jobs.isEmpty
                        ? const EmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'İlan bulunamadı',
                      subtitle:
                      'Arama veya filtreleri değiştirerek tekrar deneyebilirsin.',
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: jobs.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return _JobCard(job: job);
                      },
                    ),
                  ),
                ],
              ),
            ),
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

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailPage(jobId: job.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    job.status.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(label: job.category),
                const SizedBox(width: 8),
                _InfoChip(label: '${job.deliveryDays} gün'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                Text(
                  '₺${job.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryDark : AppColors.black,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}