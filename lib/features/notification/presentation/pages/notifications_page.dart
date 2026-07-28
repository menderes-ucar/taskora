import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/enums/app_notification_type.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../contracts/presentation/pages/contract_detail_page.dart';
import '../../../contracts/presentation/pages/my_active_jobs_page.dart';
import '../../../contracts/presentation/pages/my_active_projects_page.dart';

import '../../../freelancer/proposals/ui/pages/my_proposals_page.dart';
import '../../../jobs/presentation/pages/job_list_page.dart';
import '../../../jobs/presentation/pages/received_proposals_page.dart';

import '../../../messages/presentation/pages/messages_list_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../data/services/notification_helper.dart';
import '../../domain/providers/notification_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  void _handleNotificationTap({
    required BuildContext context,
    required WidgetRef ref,
    required AppNotification item,
  }) {
    ref.read(notificationActionProvider).markAsRead(item.id);

    switch (item.type) {
      case AppNotificationType.newMessage:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesListPage()));
        break;
      case AppNotificationType.newProposal:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivedProposalsPage()));
        break;
      case AppNotificationType.proposalAccepted:
      case AppNotificationType.proposalRejected:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProposalsPage()));
        break;
      case AppNotificationType.newJobPosted:
      case AppNotificationType.jobApproved:
      case AppNotificationType.jobRejected:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const JobListPage()));
        break;
      case AppNotificationType.walletUpdated:
      case AppNotificationType.payoutStatusChanged:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()));
        break;
      case AppNotificationType.contractCreated:
      case AppNotificationType.contractCompleted:
      case AppNotificationType.workSubmitted:
      case AppNotificationType.coinRefund:
        if (item.relatedId == null) {
          final isEmployerLike = item.type == AppNotificationType.workSubmitted;
          Navigator.push(context, MaterialPageRoute(builder: (_) => isEmployerLike ? const MyActiveProjectsPage() : const MyActiveJobsPage()));
          break;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => ContractDetailPage(contractId: item.relatedId!)));
        break;
      case AppNotificationType.systemAnnouncement:
        break;
    }
  }

  IconData _iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newMessage: return Icons.chat_bubble_outline_rounded;
      case AppNotificationType.newProposal: return Icons.description_outlined;
      case AppNotificationType.proposalAccepted: return Icons.check_circle_outline_rounded;
      case AppNotificationType.proposalRejected: return Icons.cancel_outlined;
      case AppNotificationType.jobApproved: return Icons.verified_rounded;
      case AppNotificationType.jobRejected: return Icons.gavel_rounded;
      case AppNotificationType.contractCreated: return Icons.assignment_outlined;
      case AppNotificationType.workSubmitted: return Icons.upload_file_outlined;
      case AppNotificationType.contractCompleted: return Icons.task_alt_rounded;
      case AppNotificationType.newJobPosted: return Icons.work_outline_rounded;
      case AppNotificationType.walletUpdated: return Icons.account_balance_wallet_outlined;
      case AppNotificationType.coinRefund: return Icons.monetization_on_outlined;
      case AppNotificationType.payoutStatusChanged: return Icons.payments_outlined;
      case AppNotificationType.systemAnnouncement: return Icons.campaign_outlined;
    }
  }

  Color _colorForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newMessage: return AppColors.primaryDark;
      case AppNotificationType.newProposal: return AppColors.warning;
      case AppNotificationType.proposalAccepted: return AppColors.success;
      case AppNotificationType.proposalRejected: return AppColors.danger;
      case AppNotificationType.jobApproved: return AppColors.success;
      case AppNotificationType.jobRejected: return AppColors.danger;
      case AppNotificationType.contractCreated: return const Color(0xFF7C3AED);
      case AppNotificationType.workSubmitted: return const Color(0xFF0F766E);
      case AppNotificationType.contractCompleted: return AppColors.success;
      case AppNotificationType.newJobPosted: return AppColors.primaryDark;
      case AppNotificationType.walletUpdated: return AppColors.success;
      case AppNotificationType.coinRefund: return AppColors.warning;
      case AppNotificationType.payoutStatusChanged: return const Color(0xFF2563EB);
      case AppNotificationType.systemAnnouncement: return const Color(0xFFD97706);
    }
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'Az önce';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} sa önce';
    if (difference.inDays < 7) return '${difference.inDays} gün önce';
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text('Kullanıcı oturumu bulunamadı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }

    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Bildirimler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            tooltip: 'Tümünü Okundu İşaretle',
            onPressed: () => ref.read(notificationActionProvider).markAllAsRead(currentUser.id),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('Henüz bildiriminiz yok.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final color = _colorForType(item.type);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: item.isRead
                        ? AppColors.primaryDark.withValues(alpha: 0.20)
                        : color.withValues(alpha: 0.50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onTap: () => _handleNotificationTap(context: context, ref: ref, item: item),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(_iconForType(item.type), color: color, size: 22),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w900),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.body,
                          style: const TextStyle(color: AppColors.grey, fontSize: 13, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(item.createdAt),
                        style: TextStyle(color: AppColors.grey.withValues(alpha: 0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}