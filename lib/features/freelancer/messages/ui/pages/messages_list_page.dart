import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../shared/models/message_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../logic/messages_provider.dart';
import 'chat_detail_page.dart';

class MessagesListPage extends ConsumerStatefulWidget {
  const MessagesListPage({super.key});

  @override
  ConsumerState<MessagesListPage> createState() => _MessagesListPageState();
}

class _MessagesListPageState extends ConsumerState<MessagesListPage> {
  int selectedTabIndex = 0;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays >= 1) {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

    ref.watch(messagesProvider);

    final notifier = ref.read(messagesProvider.notifier);
    final allConversations = notifier.getConversationsForUser(currentUser.id);
    final archivedConversations =
    notifier.getArchivedConversationsForUser(currentUser.id);
    final unreadConversations =
    allConversations.where((e) => e.unreadCount > 0).toList();

    final totalProposalCount = allConversations.fold<int>(
      0,
          (sum, item) => sum + item.proposalCount,
    );

    final List<ConversationPreview> visibleConversations;
    final String emptyTitle;
    final String emptySubtitle;

    switch (selectedTabIndex) {
      case 1:
        visibleConversations = unreadConversations;
        emptyTitle = 'Okunmamış mesaj yok';
        emptySubtitle = 'Yeni gelen mesajlar burada görünecek.';
        break;
      case 2:
        visibleConversations = archivedConversations;
        emptyTitle = 'Arşiv boş';
        emptySubtitle = 'Arşivlenen konuşmalar burada görünecek.';
        break;
      default:
        visibleConversations = allConversations;
        emptyTitle = 'Henüz bir konuşma yok';
        emptySubtitle = 'Teklif sonrası mesajlaşmalar burada görünecek.';
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Mesajlar'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _MessagesHero(
              conversationCount: allConversations.length,
              proposalCount: totalProposalCount,
              unreadCount: unreadConversations.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Tümü',
                    selected: selectedTabIndex == 0,
                    onTap: () {
                      setState(() => selectedTabIndex = 0);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabButton(
                    label: 'Okunmamış',
                    selected: selectedTabIndex == 1,
                    badge: unreadConversations.isEmpty
                        ? null
                        : unreadConversations.length.toString(),
                    onTap: () {
                      setState(() => selectedTabIndex = 1);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabButton(
                    label: 'Arşiv',
                    selected: selectedTabIndex == 2,
                    badge: archivedConversations.isEmpty
                        ? null
                        : archivedConversations.length.toString(),
                    onTap: () {
                      setState(() => selectedTabIndex = 2);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleConversations.isEmpty
                ? EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: emptyTitle,
              subtitle: emptySubtitle,
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              itemCount: visibleConversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conversation = visibleConversations[index];

                return _ConversationCard(
                  conversation: conversation,
                  timeText:
                  _formatTime(conversation.lastMessage.createdAt),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(
                          otherUserId: conversation.otherUser.id,
                          otherUserName: conversation.otherUser.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesHero extends StatelessWidget {
  final int conversationCount;
  final int proposalCount;
  final int unreadCount;

  const _MessagesHero({
    required this.conversationCount,
    required this.proposalCount,
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
                'INBOX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Konuşmalarını takip et, teklifleri kaçırma.',
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
                      label: 'Sohbet',
                      value: '$conversationCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroStatChip(
                      label: 'Teklif',
                      value: '$proposalCount',
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

class _ConversationCard extends StatelessWidget {
  final ConversationPreview conversation;
  final String timeText;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.timeText,
    required this.onTap,
  });

  String _previewText() {
    if (conversation.lastMessage.type == MessageType.proposal) {
      return 'Özel teklif gönderildi';
    }
    return conversation.lastMessage.text;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primary.withValues(alpha: 0.40)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.20),
                          AppColors.primaryDark.withValues(alpha: 0.16),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        conversation.otherUser.name.isNotEmpty
                            ? conversation.otherUser.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  if (conversation.isPinned)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.push_pin_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherUser.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeText,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastSeenText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _previewText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread ? AppColors.black : AppColors.grey,
                        height: 1.4,
                        fontWeight:
                        hasUnread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (conversation.proposalCount > 0)
                          _MiniBadge(
                            label: 'Teklif ${conversation.proposalCount}',
                            color: AppColors.warning,
                          ),
                        if (conversation.unreadCount > 0)
                          _MiniBadge(
                            label:
                            '${conversation.unreadCount} yeni mesaj',
                            color: AppColors.primaryDark,
                          ),
                        if (conversation.isArchived)
                          const _MiniBadge(
                            label: 'Arşiv',
                            color: AppColors.grey,
                          ),
                      ],
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
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.16)
          : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.40)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.primaryDark : AppColors.grey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryDark : AppColors.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
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