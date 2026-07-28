import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../jobs/presentation/pages/job_categories_page.dart';

import '../../../messages/presentation/pages/messages_list_page.dart';
import '../../home/ui/pages/freelancer_home_page.dart';
import '../../profile/ui/pages/freelancer_profile_page.dart';

class FreelancerMainShell extends ConsumerStatefulWidget {
  const FreelancerMainShell({super.key});

  @override
  ConsumerState<FreelancerMainShell> createState() => _FreelancerMainShellState();
}

class _FreelancerMainShellState extends ConsumerState<FreelancerMainShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    final pages = <Widget>[
      FreelancerHomePage(userName: user?.name ?? 'Freelancer'),
      const JobCategoriesPage(),
      const MessagesListPage(),
      const FreelancerProfilePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryDark.withValues(alpha: 0.15),
          elevation: 8,

          // 🔥 YAZILAR
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? AppColors.primaryDark : AppColors.grey,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 12,
            );
          }),

          // 🔥 ICONLAR
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primaryDark : AppColors.grey,
              size: 22,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() => currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'İşler',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Mesajlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}