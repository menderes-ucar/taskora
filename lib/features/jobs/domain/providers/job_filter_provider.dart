import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/enums/job_status.dart';
import '../../../../shared/models/job_model.dart';
import 'job_provider.dart';

class JobsFilterState {
  final String searchQuery;
  final String? selectedCategory;
  final double? minBudget;
  final double? maxBudget;
  final bool onlyOpenJobs;

  const JobsFilterState({
    required this.searchQuery,
    required this.selectedCategory,
    required this.minBudget,
    required this.maxBudget,
    required this.onlyOpenJobs,
  });

  factory JobsFilterState.initial() {
    return const JobsFilterState(
      searchQuery: '',
      selectedCategory: null,
      minBudget: null,
      maxBudget: null,
      onlyOpenJobs: true,
    );
  }

  JobsFilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    double? minBudget,
    double? maxBudget,
    bool? onlyOpenJobs,
    bool clearCategory = false,
    bool clearMinBudget = false,
    bool clearMaxBudget = false,
  }) {
    return JobsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
      clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      minBudget: clearMinBudget ? null : (minBudget ?? this.minBudget),
      maxBudget: clearMaxBudget ? null : (maxBudget ?? this.maxBudget),
      onlyOpenJobs: onlyOpenJobs ?? this.onlyOpenJobs,
    );
  }
}

class JobsFilterNotifier extends StateNotifier<JobsFilterState> {
  JobsFilterNotifier() : super(JobsFilterState.initial());

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      state = state.copyWith(clearCategory: true);
      return;
    }
    state = state.copyWith(selectedCategory: category);
  }

  void setMinBudget(double? value) {
    if (value == null) {
      state = state.copyWith(clearMinBudget: true);
      return;
    }
    state = state.copyWith(minBudget: value);
  }

  void setMaxBudget(double? value) {
    if (value == null) {
      state = state.copyWith(clearMaxBudget: true);
      return;
    }
    state = state.copyWith(maxBudget: value);
  }

  void setOnlyOpenJobs(bool value) {
    state = state.copyWith(onlyOpenJobs: value);
  }

  void clearAll() {
    state = JobsFilterState.initial();
  }
}

final jobsFilterProvider =
StateNotifierProvider<JobsFilterNotifier, JobsFilterState>(
      (ref) => JobsFilterNotifier(),
);

final jobCategoriesProvider = Provider<List<String>>((ref) {
  final jobs = ref.watch(openJobsProvider);
  final categories = jobs.map((job) => job.category).toSet().toList();
  categories.sort();
  return categories;
});

final filteredJobsProvider = Provider<List<JobModel>>((ref) {
  final jobs = ref.watch(openJobsProvider);
  final filter = ref.watch(jobsFilterProvider);

  return jobs.where((job) {
    if (filter.onlyOpenJobs && job.status != JobStatus.open) return false;

    if (filter.selectedCategory != null &&
        filter.selectedCategory!.trim().isNotEmpty &&
        job.category.toLowerCase() !=
            filter.selectedCategory!.toLowerCase()) {
      return false;
    }

    if (filter.minBudget != null && job.budgetMin < filter.minBudget!) {
      return false;
    }
    if (filter.maxBudget != null && job.budgetMax > filter.maxBudget!) {
      return false;
    }

    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final matchesTitle = job.title.toLowerCase().contains(query);
      final matchesDescription =
      job.description.toLowerCase().contains(query);
      final matchesCategory = job.category.toLowerCase().contains(query);

      if (!matchesTitle && !matchesDescription && !matchesCategory) {
        return false;
      }
    }

    return true;
  }).toList();
});