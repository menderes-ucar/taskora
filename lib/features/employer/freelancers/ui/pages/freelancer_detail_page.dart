import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../../../messages/presentation/pages/chat_detai_page.dart';


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
      } catch (_) {}

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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Freelancer',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            errorText ?? 'Hata',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final displayName = (profile!['name'] ?? 'İsimsiz').toString();
    final isOwnProfile =
        currentUser != null && currentUser.id == widget.freelancerId;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.28),
                        AppColors.primaryDark.withValues(alpha: 0.18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
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
                  (profile!['title'] ?? '-').toString(),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailPage(
                            otherUserId: widget.freelancerId,
                            otherUserName: displayName,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Mesaj At',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Yetenekler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildSkillsWrap(profile!['skills']),
        ],
      ),
    );
  }

  Widget _buildSkillsWrap(dynamic skillsRaw) {
    final List<String> skills = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map(
            (s) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            s,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}