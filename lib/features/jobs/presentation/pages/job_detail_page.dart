import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/proposal_Service.dart';
import '../../../../shared/enums/proposal_status.dart';
import '../../../../shared/helpers/job_category_helper.dart';
import '../../../../shared/models/job_model.dart';
import '../../../../shared/models/proposal_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../freelancer/proposals/providers/proposals_provider.dart';
import '../../../messages/presentation/pages/chat_detai_page.dart';
import '../../data/repositories/job_repositories_provider.dart';

final jobDetailProvider =
FutureProvider.family<JobModel?, String>((ref, jobId) async {
  return ref.read(jobRepositoryProvider).getJobById(jobId);
});

class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  String _employerName = 'İşveren Yükleniyor...';
  bool _isLoadingEmployer = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchEmployerName(String employerId) async {
    if (!_isLoadingEmployer) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', employerId)
          .maybeSingle();

      if (mounted && res != null && res['name'] != null) {
        setState(() {
          _employerName = res['name'].toString();
          _isLoadingEmployer = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _employerName = 'İşveren';
            _isLoadingEmployer = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _employerName = 'İşveren';
          _isLoadingEmployer = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('İş Detayları',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Center(
              child: Text('İlan bulunamadı',
                  style: TextStyle(color: Colors.white)),
            );
          }
          _fetchEmployerName(job.employerId);
          return _buildContent(context, ref, job);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white)),
        error: (error, st) => Center(
            child: Text('Hata: $error',
                style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, JobModel job) {
    final currentUser = ref.watch(authProvider).user;
    final int requiredCoinsForProposal =
    JobCategoryHelper.getCoinCostByCategory(job.category);
    const int requiredCoinsForMessage = 3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // 🚀 BEYAZ DETAY KARTI (Kategori, Başlık, Açıklama, İşveren)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KATEGORİ VE DURUM ROZETİ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 14, color: AppColors.primaryDark),
                        const SizedBox(width: 6),
                        Text(
                          'Kategori: ${job.category}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      job.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. İLAN BAŞLIĞI
              const Text(
                'İlan Başlığı',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),

              // 3. İLAN AÇIKLAMASI
              const Text(
                'İlan Açıklaması',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                job.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 14),

              // 4. İŞVEREN BİLGİSİ
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_outline,
                        size: 20, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'İlanı Yayınlayan',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isLoadingEmployer ? 'Yükleniyor...' : _employerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 🚀 BÜTÇE VE SÜRE KARTI
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                Icons.payments_outlined,
                'Bütçe',
                '₺${job.budgetMin.toStringAsFixed(0)}',
                AppColors.success,
              ),
              Container(
                  height: 30,
                  width: 1,
                  color: AppColors.primaryDark.withValues(alpha: 0.15)),
              _buildInfoItem(
                Icons.schedule_rounded,
                'Teslim Süresi',
                job.duration,
                AppColors.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // GEREKLİ YETENEKLER
        if (job.skillsRequired.isNotEmpty) ...[
          const Text('Gerekli Yetenekler',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.skillsRequired
                .map((skill) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color:
                    AppColors.primaryDark.withValues(alpha: 0.20)),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 28),
        ],

        // 🚀 ALT AKSİYON BUTONLARI (Teklif Gönder + Mesaj At)
        Row(
          children: [
            // TEKLİF GÖNDER BUTONU
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.danger,
                          content: Text(
                              'Teklif vermek için oturum açmalısınız.'),
                        ),
                      );
                      return;
                    }
                    _showSendProposalBottomSheet(
                      context,
                      ref,
                      job,
                      currentUser.id,
                      currentUser.fullName,
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Teklif Ver ($requiredCoinsForProposal Coin)',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // MESAJ AT BUTONU
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    side: BorderSide(
                      color: AppColors.primaryDark.withValues(alpha: 0.30),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (currentUser == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(
                          otherUserId: job.employerId,
                          otherUserName: _employerName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: AppColors.primaryDark),
                  label: Text(
                    'Mesaj ($requiredCoinsForMessage Coin)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(
      IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w900, color: color, fontSize: 15)),
      ],
    );
  }

  // 🚀 TEKLİF FORMU (Bottom Sheet)
  void _showSendProposalBottomSheet(
      BuildContext context,
      WidgetRef ref,
      JobModel job,
      String freelancerId,
      String freelancerName,
      ) {
    final amountController = TextEditingController();
    final daysController = TextEditingController();
    final coverLetterController = TextEditingController();
    final attachmentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Teklif Oluştur',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black)),
                const SizedBox(height: 4),
                Text(job.title,
                    style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                // Tutar
                TextFormField(
                  controller: amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: AppColors.black, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '₺ ',
                    hintText: 'Teklif tutarınız',
                    hintStyle: const TextStyle(color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Tutar girin';
                    if (double.tryParse(val.trim()) == null) {
                      return 'Geçerli rakam girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Teslim Süresi
                TextFormField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppColors.black, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Teslim Süresi (Gün)',
                    hintStyle: const TextStyle(color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Süre girin';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Açıklama / Ön Yazı
                TextFormField(
                  controller: coverLetterController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.black),
                  decoration: InputDecoration(
                    hintText: 'İşverene ön yazınız / Neden sizi seçmeli?',
                    hintStyle: const TextStyle(color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Açıklama girin'
                      : null,
                ),
                const SizedBox(height: 12),

                // Dosya / Link
                TextFormField(
                  controller: attachmentController,
                  style: const TextStyle(color: AppColors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.link_rounded,
                        color: AppColors.primaryDark),
                    hintText: 'Örnek Proje / Bağlantı Linki (İsteğe Bağlı)',
                    hintStyle:
                    const TextStyle(color: AppColors.grey, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                      // JobDetailPage.dart içerisindeki 'Teklifi Gönder' butonu onPressed bloğu:

                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final int requiredCoins = JobCategoryHelper.getCoinCostByCategory(job.category);

                        final proposal = ProposalModel(
                          id: '', // ID veritabanı (RPC) tarafından üretilecek
                          jobId: job.id,
                          freelancerId: freelancerId,
                          freelancerName: freelancerName,
                          amount: double.parse(amountController.text.trim()),
                          deliveryDays: int.parse(daysController.text.trim()),
                          coverLetter: coverLetterController.text.trim(),
                          status: ProposalStatus.pending,
                          createdAt: DateTime.now(),
                          coinCost: requiredCoins,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                        }

                        try {
                          final proposalService = SupabaseProposalService();
                          await proposalService.createProposalWithCoinDeduction(
                            proposal: proposal,
                            coinCost: requiredCoins,
                            jobCategoryId: job.category,
                          );

                          // 🚀 UI & CACHE YENİLEME: Sayfadaki teklif listesini ve bakiyeyi anında günceller
                          ref.invalidate(proposalsProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text(
                                  'Teklifiniz başarıyla iletildi! Bakiyenizden $requiredCoins Coin düşüldü. 🎉',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final cleanMsg = e
                                .toString()
                                .replaceAll('Exception: ', '')
                                .replaceAll('PostgrestException(', '')
                                .split(', code:')
                                .first
                                .trim();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.danger,
                                content: Text(cleanMsg),
                              ),
                            );
                          }
                        }
                      },
                    child: const Text('Teklifi Gönder',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}