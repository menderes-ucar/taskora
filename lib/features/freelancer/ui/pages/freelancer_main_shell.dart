import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../home/ui/pages/freelancer_home_page.dart';
import '../../jobs/ui/pages/job_categories_page.dart';
import '../../messages/ui/pages/messages_list_page.dart';
import '../../profile/ui/pages/freelancer_profile_page.dart';

class FreelancerMainShell extends ConsumerStatefulWidget {
  const FreelancerMainShell({super.key});

  @override
  ConsumerState<FreelancerMainShell> createState() =>
      _FreelancerMainShellState();
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
            backgroundColor: AppColors.black,

            indicatorColor: AppColors.primary.withOpacity(0.2),

            // 🔥 YAZILAR
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              );
            }),

            // 🔥 ICONLAR
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? Colors.white : Colors.white70,
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
                selectedIcon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'İşler',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Mesajlar',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
    );
  }
}