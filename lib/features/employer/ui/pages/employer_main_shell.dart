import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../job_board/presentation/pages/employer_job_board_page.dart';
import '../../../jobs/presentation/pages/my_pages_job.dart';
import '../../../messages/presentation/pages/messages_list_page.dart';
import '../../home/ui/pages/employer_home_page.dart';
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

    final pages = <Widget>[
      EmployerHomePage(
        userName: user?.name ?? 'İşveren',
      ),
      const MyJobsPage(),
      const EmployerJobBoardPage(),
      const MessagesListPage(),
      const EmployerProfilePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);

            return TextStyle(
              color: selected
                  ? AppColors.primaryDark
                  : AppColors.grey,
              fontWeight: selected
                  ? FontWeight.w900
                  : FontWeight.w600,
              fontSize: 11,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);

            return IconThemeData(
              color: selected
                  ? AppColors.primaryDark
                  : AppColors.grey,
              size: 22,
            );
          }),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'Proje Aç',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'Kariyer',
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