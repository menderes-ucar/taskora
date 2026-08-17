import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../jobs/presentation/pages/job_categories_page.dart'; // 🚀 PROJELERİN OLDUĞU EKRAN
import '../../../job_board/presentation/pages/freelancer_job_board_page.dart'; // 🚀 YENİ KARİYER / STAJ EKRANI
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

    // 🚀 5 TAB: Hem Freelance Projeler hem de Kariyer İlanları bir arada!
    final pages = <Widget>[
      FreelancerHomePage(userName: user?.name ?? 'Freelancer'),
      const JobCategoriesPage(),      // 1. Projeler / Teklif Verme Ekranın (Geri Eklendi)
      const FreelancerJobBoardPage(), // 2. Kariyer / Maaşlı İş / Staj İlanları (Yeni Modül)
      const MessagesListPage(),       // 3. Mesajlar
      const FreelancerProfilePage(),   // 4. Profil
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryDark.withValues(alpha: 0.15),
          elevation: 8,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? AppColors.primaryDark : AppColors.grey,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 11,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primaryDark : AppColors.grey,
              size: 22,
            );
          }),
        ),
        child: NavigationBar(
          height: 72,
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
              icon: Icon(Icons.handshake_outlined),
              selectedIcon: Icon(Icons.handshake_rounded),
              label: 'Projeler', // 🚀 Eski Projelerin
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'Kariyer',  // 🚀 Yeni İş & Staj Pano Modülü
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