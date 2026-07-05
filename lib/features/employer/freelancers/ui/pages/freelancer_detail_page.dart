import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../freelancer/messages/ui/pages/chat_detail_page.dart';


class FreelancerDetailPage extends ConsumerStatefulWidget {
  final String freelancerId;

  const FreelancerDetailPage({
    super.key,
    required this.freelancerId,
  });

  @override
  ConsumerState<FreelancerDetailPage> createState() =>
      _FreelancerDetailPageState();
}

class _FreelancerDetailPageState extends ConsumerState<FreelancerDetailPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> portfolioItems = [];
  bool isLoading = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _loadFreelancer();
  }

  Future<void> _loadFreelancer() async {
    try {
      setState(() {
        isLoading = true;
        errorText = null;
      });

      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.freelancerId)
          .maybeSingle();

      if (profileResponse == null) {
        setState(() {
          profile = null;
          portfolioItems = [];
          isLoading = false;
          errorText = 'Freelancer bulunamadı';
        });
        return;
      }

      List<Map<String, dynamic>> portfolioResponse = [];
      try {
        final result = await supabase
            .from('portfolio_items')
            .select()
            .eq('freelancer_id', widget.freelancerId)
            .order('created_at', ascending: false);

        portfolioResponse =
        List<Map<String, dynamic>>.from(result as List<dynamic>);
      } catch (_) {
        portfolioResponse = [];
      }

      setState(() {
        profile = Map<String, dynamic>.from(profileResponse);
        portfolioItems = portfolioResponse;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorText = 'Hata: $e';
        isLoading = false;
      });
    }
  }

  void _goToChat({
    required String otherUserId,
    required String otherUserName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          scrolledUnderElevation: 0,
          title: const Text('Freelancer'),
        ),
        body: Center(
          child: Text(errorText ?? 'Freelancer bulunamadı'),
        ),
      );
    }

    final name = (profile!['name'] ?? '').toString();
    final title = (profile!['title'] ?? '-').toString();
    final bio = (profile!['bio'] ?? '').toString();
    final rating = (profile!['rating'] ?? 0).toString();
    final reviewCount = (profile!['review_count'] ?? 0).toString();
    final completedJobs = (profile!['completed_jobs'] ?? 0).toString();

    final skillsRaw = profile!['skills'];
    final List<String> skills = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final displayName = name.isEmpty ? 'İsimsiz Kullanıcı' : name;
    final isOwnProfile =
        currentUser != null && currentUser.id == widget.freelancerId;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        scrolledUnderElevation: 0,
        title: const Text('Freelancer Profili'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 38,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(title: 'Puan', value: rating),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(title: 'Yorum', value: reviewCount),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(title: 'İş', value: completedJobs),
                    ),
                  ],
                ),
                if (!isOwnProfile) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: currentUser == null
                          ? null
                          : () => _goToChat(
                        otherUserId: widget.freelancerId,
                        otherUserName: displayName,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(
                        currentUser == null ? 'Giriş yapmalısın' : 'Mesaj At',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yetenekler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                if (skills.isEmpty)
                  const Text(
                    'Henüz yetenek eklenmemiş.',
                    style: TextStyle(color: AppColors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (skill) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Portföy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                if (portfolioItems.isEmpty)
                  const Text(
                    'Henüz portföy eklenmemiş.',
                    style: TextStyle(color: AppColors.grey),
                  )
                else
                  ...portfolioItems.map(
                        (item) {
                      final imagesRaw = item['image_urls'];
                      final imageUrls = imagesRaw is List
                          ? imagesRaw.map((e) => e.toString()).toList()
                          : <String>[];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrls.isNotEmpty)
                                SizedBox(
                                  height: 170,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: PageView.builder(
                                      itemCount: imageUrls.length,
                                      itemBuilder: (context, index) {
                                        final imageUrl = imageUrls[index];

                                        return Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) {
                                            return Container(
                                              color: AppColors.black,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item['title'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (item['category'] ?? '').toString(),
                                      style: const TextStyle(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (item['description'] ?? '').toString(),
                                      style: const TextStyle(
                                        color: AppColors.grey,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _MiniStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}