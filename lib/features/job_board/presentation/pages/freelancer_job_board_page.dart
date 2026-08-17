import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/job_board_enums.dart';
import '../../../../shared/constants/job_categories.dart';
import '../../../../shared/models/job_posting_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../providers/job_board_providers.dart';

class FreelancerJobBoardPage extends ConsumerStatefulWidget {
  const FreelancerJobBoardPage({super.key});

  @override
  ConsumerState<FreelancerJobBoardPage> createState() => _FreelancerJobBoardPageState();
}

class _FreelancerJobBoardPageState extends ConsumerState<FreelancerJobBoardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedCategory;
  WorkType? _selectedWorkType;
  ContractType? _selectedContractType;

  final List<String> _categories = [
    'Tümü',
    ...TaskoraJobCategories.values,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Kariyer & İş İlanları',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'İlanları Keşfet'),
            Tab(text: 'Başvurularım'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobPostingsTab(context),
          if (user != null)
            _buildMyApplicationsTab(context, user.id)
          else
            const Center(
              child: Text(
                'Oturum açmanız gerekiyor',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // 🚀 TAB 1: İLAN ARAMA, FİLTRELEME VE 2'Lİ GRID KARTLAR
  Widget _buildJobPostingsTab(BuildContext context) {
    final approvedJobsAsync = ref.watch(approvedJobPostingsStreamProvider);

    return Column(
      children: [
        // Arama & Filtreleme Kutusu
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Arama Çubuğu
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w600, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Pozisyon veya teknoloji ara...',
                  hintStyle: const TextStyle(color: AppColors.grey, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryDark, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.20)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Yatay Kategori Çipleri
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final isSelected = (idx == 0 && _selectedCategory == null) ||
                        _selectedCategory == cat;

                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primaryDark,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primaryDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 11,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = (idx == 0) ? null : cat;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.25),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Dropdown Filtreleri
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown<WorkType?>(
                      value: _selectedWorkType,
                      hint: 'Çalışma Şekli',
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tümü')),
                        ...WorkType.values.map(
                              (w) => DropdownMenuItem(value: w, child: Text(w.label)),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedWorkType = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDropdown<ContractType?>(
                      value: _selectedContractType,
                      hint: 'Sözleşme Tipi',
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tümü')),
                        ...ContractType.values.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedContractType = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // İlan Listesi (Satırda 2 Kart Yapısı)
        Expanded(
          child: approvedJobsAsync.when(
            data: (jobs) {
              final filtered = jobs.where((job) {
                final query = _searchQuery.toLowerCase();
                final matchesSearch = query.isEmpty ||
                    job.title.toLowerCase().contains(query) ||
                    job.category.toLowerCase().contains(query) ||
                    job.description.toLowerCase().contains(query);

                final matchesCategory = _selectedCategory == null ||
                    job.category.toLowerCase().contains(_selectedCategory!.toLowerCase());

                final matchesWork = _selectedWorkType == null || job.workType == _selectedWorkType;
                final matchesContract = _selectedContractType == null || job.contractType == _selectedContractType;

                return matchesSearch && matchesCategory && matchesWork && matchesContract;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 48, color: Colors.white70),
                      const SizedBox(height: 8),
                      Text(
                        jobs.isEmpty
                            ? 'Sistemde onaylı iş ilanı yok.'
                            : 'Kriterlere uygun ilan bulunamadı.',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              // 🚀 SATIRDA 2 KART (2 COLUMNS GRID)
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final job = filtered[idx];
                  return _buildGridJobCard(context, job);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (err, _) => Center(
              child: Text('Hata: $err', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  // 🚀 TAB 2: BAŞVURDUKLARIM
  Widget _buildMyApplicationsTab(BuildContext context, String freelancerId) {
    final myAppsAsync = ref.watch(freelancerApplicationsStreamProvider(freelancerId));

    return myAppsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.assignment_turned_in_outlined, size: 54, color: Colors.white70),
                SizedBox(height: 12),
                Text(
                  'Henüz bir ilana başvurmadınız.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        final activeApps = apps.where((a) => a.status == ApplicationStatus.pending || a.status == ApplicationStatus.reviewed).toList();
        final pastApps = apps.where((a) => a.status == ApplicationStatus.accepted || a.status == ApplicationStatus.rejected).toList();

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.20)),
                ),
                child: const TabBar(
                  indicatorColor: AppColors.primaryDark,
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: AppColors.grey,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'Devam Edenler'),
                    Tab(text: 'Sonuçlananlar'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildApplicationListView(activeApps, 'Aktif başvurunuz yok.'),
                    _buildApplicationListView(pastApps, 'Geçmiş başvurunuz yok.'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (err, _) => Center(
        child: Text('Hata: $err', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildApplicationListView(List<dynamic> apps, String emptyText) {
    if (apps.isEmpty) {
      return Center(
        child: Text(emptyText, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: apps.length,
      itemBuilder: (ctx, idx) {
        final app = apps[idx];
        final statusColor = Color(
          int.parse(app.status.colorCode.replaceAll('#', '0xFF')),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Başvuru #${app.id.substring(0, 8)}',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor, width: 0.8),
                    ),
                    child: Text(
                      app.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Önyazı: ${app.coverLetter}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🚀 BEYAZ KARTLI SATIRDA 2 TANE YAN YANA İLAN KARTI
  Widget _buildGridJobCard(BuildContext context, JobPosting job) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              job.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          _buildMiniTag(job.workType.label, Icons.location_city_rounded),
          const SizedBox(height: 4),
          _buildMiniTag(job.contractType.label, Icons.description_rounded),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showApplyModal(context, job),
              child: const Text(
                'Başvur (20 Coin)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniTag(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppColors.primaryDark),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.20)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
          dropdownColor: Colors.white,
          isExpanded: true,
          style: const TextStyle(color: AppColors.black, fontSize: 11, fontWeight: FontWeight.bold),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showApplyModal(BuildContext context, JobPosting job) {
    final coverLetterController = TextEditingController();
    const double coinCost = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${job.title} Başvurusu',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Başvuru bedeli 20 coindir. İade edilmez.',
                      style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: coverLetterController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w600, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Kendinizden ve deneyimlerinizden bahsedin...',
                hintStyle: const TextStyle(color: AppColors.grey, fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.20)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final user = ref.read(authProvider).user;
                  if (user == null) return;

                  try {
                    final service = ref.read(jobBoardServiceProvider);
                    await service.applyToJobPosting(
                      jobPostingId: job.id,
                      freelancerId: user.id,
                      coverLetter: coverLetterController.text.trim(),
                      coinCost: coinCost,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text('Başvurunuz iletildi! 🪙'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      final msg = e.toString().replaceAll('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.danger,
                          content: Text(msg),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Başvuruyu Gönder (20 Coin)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}