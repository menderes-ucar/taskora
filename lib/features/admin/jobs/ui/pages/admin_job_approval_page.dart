import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/enums/app_notification_type.dart';
import '../../../../notification/data/services/notification_helper.dart';
import '../../../admin_guard.dart';

class AdminJobApprovalPage extends StatefulWidget {
  const AdminJobApprovalPage({super.key});

  @override
  State<AdminJobApprovalPage> createState() => _AdminJobApprovalPageState();
}

class _AdminJobApprovalPageState extends State<AdminJobApprovalPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _allJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllJobs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('jobs').select('''
            *,
            employer:profiles!employer_id(*)
          ''').order('created_at', ascending: false);

      setState(() {
        _allJobs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('İlanlar çekilirken hata: $e'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String jobId, String newStatus, String employerId) async {
    final nowIso = DateTime.now().toIso8601String();

    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
      };

      if (newStatus == 'open') {
        updateData['approved_at'] = nowIso;
      }

      await _supabase.from('jobs').update(updateData).eq('id', jobId);

      if (employerId.isNotEmpty) {
        await NotificationHelper.send(
          targetUserId: employerId,
          title: newStatus == 'open' ? 'İlanınız Onaylandı! 🎉' : 'İlanınız Reddedildi ❌',
          body: newStatus == 'open'
              ? 'Yayınladığınız ilan onaylandı ve listelerde görünür hale geldi.'
              : 'Yayınladığınız ilan platform kurallarına uymadığı için reddedildi.',
          type: newStatus == 'open'
              ? AppNotificationType.jobApproved.name
              : AppNotificationType.jobRejected.name,
          relatedId: jobId,
        );
      }

      setState(() {
        final index = _allJobs.indexWhere((j) => j['id'] == jobId);
        if (index != -1) {
          _allJobs[index]['status'] = newStatus;
          if (newStatus == 'open') {
            _allJobs[index]['approved_at'] = nowIso;
          }
        }
      });
    } catch (e) {
      debugPrint('Hata: $e');
    }
  }

  void _showEmployerDetails(Map<String, dynamic>? employer) {
    if (employer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('İşveren profil bilgisi bulunamadı.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  backgroundImage: employer['avatar_url'] != null
                      ? NetworkImage(employer['avatar_url'])
                      : null,
                  child: employer['avatar_url'] == null
                      ? const Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employer['name']?.isNotEmpty == true
                            ? employer['name']
                            : 'İsimsiz Kullanıcı',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employer['email'] ?? '-',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            _DetailRow(
              icon: Icons.phone_rounded,
              label: 'Telefon',
              value: employer['phone'] ?? 'Belirtilmedi',
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.badge_rounded,
              label: 'Rol',
              value: (employer['role'] ?? 'employer').toString().toUpperCase(),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.monetization_on_rounded,
              label: 'Mevcut Bakiye',
              value: '₺${employer['coins'] ?? 0}',
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.verified_user_rounded,
              label: 'Abonelik Durumu',
              value: employer['is_subscribed'] == true ? 'Premium' : 'Ücretsiz Plan',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingJobs = _allJobs.where((j) => j['status'] == 'pending').toList();
    final approvedJobs = _allJobs.where((j) => j['status'] == 'open').toList();
    final rejectedJobs = _allJobs.where((j) => j['status'] == 'rejected').toList();

    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          title: const Text("İlan Onay & Yönetim Merkezi"),
          backgroundColor: AppColors.dark,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchAllJobs,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "Bekleyen (${pendingJobs.length})"),
              Tab(text: "Onaylanan (${approvedJobs.length})"),
              Tab(text: "Reddedilen (${rejectedJobs.length})"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _JobList(
              jobs: pendingJobs,
              onApprove: (id, empId) => _updateStatus(id, 'open', empId),
              onReject: (id, empId) => _updateStatus(id, 'rejected', empId),
              onShowEmployer: _showEmployerDetails,
            ),
            _JobList(
              jobs: approvedJobs,
              isApprovedList: true,
              onReject: (id, empId) => _updateStatus(id, 'rejected', empId),
              onShowEmployer: _showEmployerDetails,
            ),
            _JobList(
              jobs: rejectedJobs,
              isRejectedList: true,
              onApprove: (id, empId) => _updateStatus(id, 'open', empId),
              onShowEmployer: _showEmployerDetails,
            ),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final bool isApprovedList;
  final bool isRejectedList;
  final Function(String jobId, String employerId)? onApprove;
  final Function(String jobId, String employerId)? onReject;
  final Function(Map<String, dynamic>?) onShowEmployer;

  const _JobList({
    required this.jobs,
    this.isApprovedList = false,
    this.isRejectedList = false,
    this.onApprove,
    this.onReject,
    required this.onShowEmployer,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Center(
        child: Text(
          "Bu kategoride ilan bulunamadı.",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final job = jobs[i];
        final employer = job['employer'] as Map<String, dynamic>?;
        final employerId = job['employer_id']?.toString() ?? employer?['id']?.toString() ?? '';
        final approvedAtRaw = job['approved_at'];
        String? formattedApprovedAt;

        if (approvedAtRaw != null) {
          final dt = DateTime.tryParse(approvedAtRaw.toString())?.toLocal();
          if (dt != null) {
            formattedApprovedAt =
            "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job['title'] ?? 'Başlıksız İlan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '₺${job['budget_max'] ?? job['budget_min'] ?? 0}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (isApprovedList && formattedApprovedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Onaylanma Tarihi: $formattedApprovedAt',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(color: Colors.white10, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => onShowEmployer(employer),
                    icon: const Icon(Icons.person_search_rounded, size: 18),
                    label: Text(
                      employer?['name']?.isNotEmpty == true
                          ? employer!['name']
                          : 'İşveren Profili',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Row(
                    children: [
                      if (onReject != null && !isRejectedList)
                        IconButton(
                          tooltip: 'İlanı Reddet',
                          icon: const Icon(Icons.cancel,
                              color: AppColors.danger, size: 26),
                          onPressed: () => onReject!(job['id'], employerId),
                        ),
                      if (onApprove != null && !isApprovedList)
                        IconButton(
                          tooltip: 'İlanı Onayla',
                          icon: const Icon(Icons.check_circle,
                              color: AppColors.success, size: 26),
                          onPressed: () => onApprove!(job['id'], employerId),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text('$label: ',
            style: const TextStyle(color: AppColors.grey, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}