import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/providers/messages_proivder.dart';
import 'chat_detai_page.dart';

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
        backgroundColor: AppColors.primary,
        body: Center(
          child: Text('Kullanıcı bulunamadı', style: TextStyle(color: Colors.white)),
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

    switch (selectedTabIndex) {
      case 1:
        visibleConversations = unreadConversations;
        break;
      case 2:
        visibleConversations = archivedConversations;
        break;
      default:
        visibleConversations = allConversations;
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Mesajlar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
                    onTap: () => setState(() => selectedTabIndex = 0),
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
                    onTap: () => setState(() => selectedTabIndex = 1),
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
                    onTap: () => setState(() => selectedTabIndex = 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleConversations.isEmpty
                ? const Center(
              child: Text(
                'Henüz sohbet bulunmuyor.',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              itemCount: visibleConversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conversation = visibleConversations[index];

                return _ConversationCard(
                  conversation: conversation,
                  timeText: _formatTime(conversation.lastMessage.createdAt),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2238), Color(0xFF103847), Color(0xFF0BA99C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MESAJ MERKEZİ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Anlık iletişim kurun, özel teklifleri yönetin.',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _HeroStatChip(label: 'Sohbet', value: '$conversationCount')),
              const SizedBox(width: 10),
              Expanded(child: _HeroStatChip(label: 'Teklif', value: '$proposalCount')),
              const SizedBox(width: 10),
              Expanded(child: _HeroStatChip(label: 'Okunmamış', value: '$unreadCount')),
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

  const _HeroStatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    conversation.otherUser.name.isNotEmpty
                        ? conversation.otherUser.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            conversation.otherUser.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            timeText,
                            style: const TextStyle(color: AppColors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
              ],
            ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.primaryDark.withValues(alpha: 0.20),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}