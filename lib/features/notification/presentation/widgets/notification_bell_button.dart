import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/providers/notification_provider.dart';
import '../pages/notifications_page.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}