import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../shared/enums/app_notification_type.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../contracts/ui/pages/contract_detail_page.dart';
import '../../../../employer/contracts/ui/pages/my_active_projects_page.dart';
import '../../../../employer/jobs/ui/pages/received_proposals_page.dart';
import '../../../contracts/ui/pages/my_active_jobs_page.dart';
import '../../../messages/ui/pages/messages_list_page.dart';
import '../../../proposals/ui/pages/my_proposals_page.dart';
import '../../logic/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref.read(notificationsProvider.notifier).loadForUser(currentUser.id);
      }
    });
  }

  void _handleNotificationTap({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic item,
    required String userId,
  }) {
    ref.read(notificationsProvider.notifier).markAsRead(
      notificationId: item.id,
      userId: userId,
    );

    switch (item.type) {
      case AppNotificationType.newMessage:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MessagesListPage(),
          ),
        );
        break;

      case AppNotificationType.newProposal:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReceivedProposalsPage(),
          ),
        );
        break;

      case AppNotificationType.proposalAccepted:
      case AppNotificationType.proposalRejected:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyProposalsPage(),
          ),
        );
        break;

      case AppNotificationType.contractCreated:
      case AppNotificationType.contractCompleted:
      case AppNotificationType.workSubmitted:
        if (item.relatedId == null) {
          final isEmployerLike =
              item.type == AppNotificationType.workSubmitted;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => isEmployerLike
                  ? const MyActiveProjectsPage()
                  : const MyActiveJobsPage(),
            ),
          );
          break;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailPage(
              contractId: item.relatedId!,
            ),
          ),
        );
        break;
    }
  }

  IconData _iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newMessage:
        return Icons.chat_bubble_outline_rounded;
      case AppNotificationType.newProposal:
        return Icons.description_outlined;
      case AppNotificationType.proposalAccepted:
        return Icons.check_circle_outline_rounded;
      case AppNotificationType.proposalRejected:
        return Icons.cancel_outlined;
      case AppNotificationType.contractCreated:
        return Icons.assignment_outlined;
      case AppNotificationType.workSubmitted:
        return Icons.upload_file_outlined;
      case AppNotificationType.contractCompleted:
        return Icons.task_alt_rounded;
    }
  }

  Color _colorForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newMessage:
        return AppColors.primaryDark;
      case AppNotificationType.newProposal:
        return AppColors.warning;
      case AppNotificationType.proposalAccepted:
        return AppColors.success;
      case AppNotificationType.proposalRejected:
        return AppColors.danger;
      case AppNotificationType.contractCreated:
        return const Color(0xFF7C3AED);
      case AppNotificationType.workSubmitted:
        return const Color(0xFF0F766E);
      case AppNotificationType.contractCompleted:
        return AppColors.success;
    }
  }

  String _labelForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newMessage:
        return 'Mesaj';
      case AppNotificationType.newProposal:
        return 'Teklif';
      case AppNotificationType.proposalAccepted:
        return 'Onay';
      case AppNotificationType.proposalRejected:
        return 'Red';
      case AppNotificationType.contractCreated:
        return 'Sözleşme';
      case AppNotificationType.workSubmitted:
        return 'Teslim';
      case AppNotificationType.contractCompleted:
        return 'Tamamlandı';
    }
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    }
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı bulunamadı'),
        ),
      );
    }

    final notifier = ref.read(notificationsProvider.notifier);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((e) => !e.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Bildirimler'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.markAllAsRead(currentUser.id);
            },
            child: const Text(
              'Tümünü oku',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _NotificationsHero(
              totalCount: notifications.length,
              unreadCount: unreadCount,
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Henüz bildirim yok',
              subtitle:
              'Yeni mesaj, teklif ve sözleşme hareketleri burada görünecek.',
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final color = _colorForType(item.type);

                return Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      _handleNotificationTap(
                        context: context,
                        ref: ref,
                        item: item,
                        userId: currentUser.id,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: item.isRead
                              ? AppColors.border
                              : color.withValues(alpha: 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black
                                .withValues(alpha: 0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _iconForType(item.type),
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: item.isRead
                                              ? FontWeight.w700
                                              : FontWeight.w800,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _TypePill(
                                      label: _labelForType(item.type),
                                      color: color,
                                    ),
                                    if (!item.isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.body,
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _timeAgo(item.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHero extends StatelessWidget {
  final int totalCount;
  final int unreadCount;

  const _NotificationsHero({
    required this.totalCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E2238),
            Color(0xFF103847),
            Color(0xFF0BA99C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -12,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -24,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ALERTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mesaj, teklif ve proje hareketlerini tek ekranda takip et.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroStatChip(
                      label: 'Toplam',
                      value: '$totalCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroStatChip(
                      label: 'Yeni',
                      value: '$unreadCount',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final Color color;

  const _TypePill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}