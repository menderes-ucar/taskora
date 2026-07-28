import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/report_service.dart';
import '../../../../shared/models/message_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../employer/freelancers/ui/pages/freelancer_detail_page.dart';
import '../../domain/providers/messages_proivder.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatDetailPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final currentUser = ref.read(authProvider).user;
    final text = _messageController.text.trim();

    if (currentUser == null || text.isEmpty) return;

    await ref.read(messagesProvider.notifier).sendMessage(
      senderId: currentUser.id,
      receiverId: widget.otherUserId,
      text: text,
    );

    _messageController.clear();
  }

  void _openOtherUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FreelancerDetailPage(
          freelancerId: widget.otherUserId,
        ),
      ),
    );
  }

  void _showReportDialog(String currentUserId) {
    final reasonController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.report_problem_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text(
              'Kullanıcıyı Şikayet Et',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: reasonController,
                style: const TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'Şikayet Sebebi (Örn: Taciz, Hakaret)',
                  hintStyle: const TextStyle(color: AppColors.grey),
                  filled: true,
                  fillColor: AppColors.primary.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) =>
                val == null || val.trim().isEmpty ? 'Sebep girin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'Detaylı Açıklama...',
                  hintStyle: const TextStyle(color: AppColors.grey),
                  filled: true,
                  fillColor: AppColors.primary.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Açıklama girin'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal',
                style: TextStyle(
                    color: AppColors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final reason = reasonController.text.trim();
              final desc = descriptionController.text.trim();

              Navigator.pop(ctx);

              try {
                await ReportService().createReport(
                  reporterId: currentUserId,
                  targetId: widget.otherUserId,
                  reason: reason,
                  description: desc,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text(
                          'Şikayetiniz inceleme için admine iletildi. 🎉'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text('Şikayet gönderilemedi: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Şikayeti Gönder',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showConversationProposals(List<MessageModel> conversationMessages) {
    final proposalMessages = conversationMessages
        .where((message) => message.type == MessageType.proposal)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: proposalMessages.isEmpty
                ? const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Bu konuşmada henüz teklif yok.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey,
                  ),
                ),
              ),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 50,
                    height: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bu Konuşmadaki Teklifler',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: proposalMessages.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = proposalMessages[index];
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primaryDark
                                .withValues(alpha: 0.20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                              AppColors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_offer_rounded,
                                  size: 18,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Özel Teklif',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.black,
                                  ),
                                ),
                                const Spacer(),
                                _ProposalStatusBadge(
                                  status: message.proposalStatus ??
                                      'pending',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              message.proposalDescription ?? '',
                              style: const TextStyle(
                                color: AppColors.grey,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '₺${message.proposalAmount?.toStringAsFixed(0) ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${message.proposalDeliveryDays ?? '-'} gün',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSendProposalSheet() {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    final amountController = TextEditingController();
    final deliveryDaysController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            28,
            28,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: SizedBox(
                      width: 50,
                      height: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Özel Teklif Gönder',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.otherUserName} kullanıcısına özel teklif oluştur',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Teklif tutarı (₺)',
                      hintStyle: const TextStyle(color: AppColors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.20),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.20),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.primaryDark,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tutar gir';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Geçerli bir tutar gir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: deliveryDaysController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Teslim süresi (gün)',
                      hintStyle: const TextStyle(color: AppColors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.20),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.20),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.primaryDark,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Teslim süresi gir';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Geçerli bir gün sayısı gir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 5,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Teklif açıklaması',
                      hintStyle: const TextStyle(color: AppColors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.20),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primaryDark.withValues(alpha: 0.20),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.primaryDark,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Açıklama gir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        await ref
                            .read(messagesProvider.notifier)
                            .sendProposalMessage(
                          senderId: currentUser.id,
                          receiverId: widget.otherUserId,
                          proposalId: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          amount:
                          double.parse(amountController.text.trim()),
                          deliveryDays: int.parse(
                            deliveryDaysController.text.trim(),
                          ),
                          description: descriptionController.text.trim(),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text('Özel teklif gönderildi'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Teklifi Gönder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConversationActions({
    required List<MessageModel> conversationMessages,
    required int conversationProposalCount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) {
        final currentUser = ref.read(authProvider).user;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _ActionSheetTile(
                  icon: Icons.person_outline,
                  title: 'Profile Git',
                  onTap: () {
                    Navigator.pop(context);
                    _openOtherUserProfile();
                  },
                ),
                _ActionSheetTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Teklifler',
                  badge: conversationProposalCount > 0
                      ? conversationProposalCount.toString()
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _showConversationProposals(conversationMessages);
                  },
                ),
                _ActionSheetTile(
                  icon: Icons.report_gmailerrorred_outlined,
                  title: 'Şikayet Et',
                  isDanger: true,
                  onTap: () {
                    Navigator.pop(context);
                    if (currentUser != null) {
                      _showReportDialog(currentUser.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
            child: Text('Kullanıcı bulunamadı',
                style: TextStyle(color: Colors.white))),
      );
    }

    final List<String> ids = [currentUser.id, widget.otherUserId]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';

    ref.watch(messagesProvider);

    final conversationMessages = ref
        .read(messagesProvider.notifier)
        .getMessagesForConversation(conversationId);

    final conversationProposalCount = conversationMessages
        .where((message) => message.type == MessageType.proposal)
        .length;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Aktif Sohbet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _MiniActionButton(
                        icon: Icons.person_outline,
                        label: 'Profil',
                        onTap: _openOtherUserProfile,
                      ),
                      const SizedBox(width: 10),
                      _MiniActionButton(
                        icon: Icons.local_offer_outlined,
                        label: 'Teklifler',
                        badge: conversationProposalCount > 0
                            ? conversationProposalCount.toString()
                            : null,
                        onTap: () {
                          _showConversationProposals(conversationMessages);
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showConversationActions(
                      conversationMessages: conversationMessages,
                      conversationProposalCount: conversationProposalCount,
                    );
                  },
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          Expanded(
            child: conversationMessages.isEmpty
                ? const Center(
              child: Text(
                'Henüz mesaj yok.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: conversationMessages.length,
              itemBuilder: (context, index) {
                final message = conversationMessages[index];
                final isMe = message.senderId == currentUser.id;

                return _MessageBubble(
                  message: message,
                  isMe: isMe,
                  timeText: _formatTime(message.createdAt),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border(
                top: BorderSide(
                    color: AppColors.primaryDark.withValues(alpha: 0.20)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Mesaj yaz...',
                          hintStyle: const TextStyle(color: AppColors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: AppColors.primaryDark
                                  .withValues(alpha: 0.20),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: AppColors.primaryDark
                                  .withValues(alpha: 0.20),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: AppColors.primaryDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _BottomActionTextButton(
                      icon: Icons.attach_file_rounded,
                      label: 'Dosya Ekle',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                            Text('Dosya ekleme özelliği hazırlanıyor...'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _BottomActionTextButton(
                      icon: Icons.local_offer_outlined,
                      label: 'Özel Teklif Gönder',
                      onTap: _showSendProposalSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final String timeText;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProposal = message.type == MessageType.proposal;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isProposal)
            _ProposalMessageCard(
              message: message,
              isMe: isMe,
            )
          else
            Container(
              constraints: const BoxConstraints(maxWidth: 290),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 18),
                ),
                border: Border.all(
                  color: AppColors.primaryDark.withValues(alpha: 0.20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
            child: Text(
              timeText,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalMessageCard extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;

  const _ProposalMessageCard({
    required this.message,
    required this.isMe,
  });

  Color _statusColor() {
    switch (message.proposalStatus) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _statusText() {
    switch (message.proposalStatus) {
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final proposalId = message.proposalId;
    if (proposalId == null) return;

    await ref.read(messagesProvider.notifier).updateProposalMessageStatus(
      proposalId: proposalId,
      status: 'rejected',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Özel teklif reddedildi'),
        ),
      );
    }
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    final proposalId = message.proposalId;
    if (proposalId == null) return;

    await ref.read(messagesProvider.notifier).updateProposalMessageStatus(
      proposalId: proposalId,
      status: 'accepted',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Özel teklif kabul edildi'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 18,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 6),
              const Text(
                'Özel Teklif',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusText(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.proposalDescription ?? '',
            style: const TextStyle(
              color: AppColors.grey,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₺${message.proposalAmount?.toStringAsFixed(0) ?? '-'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${message.proposalDeliveryDays ?? '-'} gün',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          if (!isMe && message.proposalStatus == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async => _handleReject(context, ref),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primaryDark.withValues(alpha: 0.20),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Reddet',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async => _handleAccept(context, ref),
                    child: const Text('Kabul Et',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProposalStatusBadge extends StatelessWidget {
  final String status;

  const _ProposalStatusBadge({
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _statusText() {
    switch (status) {
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusText(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
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
                    color: AppColors.danger,
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

class _BottomActionTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionTextButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;
  final bool isDanger;

  const _ActionSheetTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.black;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: badge == null
          ? const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.grey,
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.danger,
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
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}