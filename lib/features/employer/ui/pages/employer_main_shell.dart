import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../freelancer/messages/ui/pages/messages_list_page.dart';
import '../../home/ui/pages/employer_home_page.dart';
import '../../jobs/ui/pages/my_jobs_page.dart';
import '../../profile/ui/pages/employer_profile_page.dart';

class EmployerMainShell extends ConsumerStatefulWidget {
  const EmployerMainShell({super.key});

  @override
  ConsumerState<EmployerMainShell> createState() => _EmployerMainShellState();
}

class _EmployerMainShellState extends ConsumerState<EmployerMainShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    final pages = [
      EmployerHomePage(userName: user?.name ?? 'İşveren'),
      const MyJobsPage(),
      const MessagesListPage(),
      const EmployerProfilePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.black,
            indicatorColor: AppColors.primary.withOpacity(0.2),

            // 🔥 yazılar
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              );
            }),

            // 🔥 iconlar
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
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'İlanlarım',
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