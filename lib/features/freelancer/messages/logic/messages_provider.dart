import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/mock_data.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../data/message_repository.dart';
import '../data/message_repository_provider.dart';

class ConversationPreview {
  final String conversationId;
  final UserModel otherUser;
  final MessageModel lastMessage;
  final int unreadCount;
  final int proposalCount;
  final bool isArchived;
  final bool isPinned;
  final String lastSeenText;

  const ConversationPreview({
    required this.conversationId,
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
    required this.proposalCount,
    required this.isArchived,
    required this.isPinned,
    required this.lastSeenText,
  });
}

class MessagesNotifier extends StateNotifier<List<MessageModel>> {
  MessagesNotifier(this.ref) : super([]) {
    loadMessages();
  }

  final Ref ref;

  MessageRepository get _repository => ref.read(messageRepositoryProvider);

  Future<void> loadMessages() async {
    state = await _repository.getAllMessages();
  }

  List<MessageModel> getMessagesForConversation(String conversationId) {
    return state
        .where((message) => message.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    await _repository.sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
    );
    await loadMessages();
  }

  Future<void> sendProposalMessage({
    required String senderId,
    required String receiverId,
    required String proposalId,
    required double amount,
    required int deliveryDays,
    required String description,
    String proposalStatus = 'pending',
  }) async {
    await _repository.sendProposalMessage(
      senderId: senderId,
      receiverId: receiverId,
      proposalId: proposalId,
      amount: amount,
      deliveryDays: deliveryDays,
      description: description,
      proposalStatus: proposalStatus,
    );
    await loadMessages();
  }

  Future<void> updateProposalMessageStatus({
    required String proposalId,
    required String status,
  }) async {
    await _repository.updateProposalMessageStatus(
      proposalId: proposalId,
      status: status,
    );
    await loadMessages();
  }

  List<ConversationPreview> getConversationsForUser(String userId) {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return [];

    final relatedMessages = state.where((message) {
      return message.senderId == userId || message.receiverId == userId;
    }).toList();

    final Map<String, List<MessageModel>> grouped = {};

    for (final message in relatedMessages) {
      grouped.putIfAbsent(message.conversationId, () => []).add(message);
    }

    final List<ConversationPreview> conversations = [];

    for (final entry in grouped.entries) {
      final messages = List<MessageModel>.from(entry.value)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (messages.isEmpty) continue;

      final lastMessage = messages.last;

      final otherUserId = lastMessage.senderId == userId
          ? lastMessage.receiverId
          : lastMessage.senderId;

      final otherUser = MockData.getUserById(otherUserId) ??
          UserModel(
            id: otherUserId,
            name: 'Kullanıcı',
            email: '',
            role: currentUser.role,
          );

      final proposalCount =
          messages.where((m) => m.type == MessageType.proposal).length;

      conversations.add(
        ConversationPreview(
          conversationId: entry.key,
          otherUser: otherUser,
          lastMessage: lastMessage,
          unreadCount: 0,
          proposalCount: proposalCount,
          isArchived: false,
          isPinned: proposalCount > 0,
          lastSeenText: 'Son mesaj',
        ),
      );
    }

    conversations.sort(
          (a, b) => b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt),
    );

    return conversations;
  }

  List<ConversationPreview> getArchivedConversationsForUser(String userId) {
    return getConversationsForUser(userId)
        .where((conversation) => conversation.isArchived)
        .toList();
  }
}

final messagesProvider =
StateNotifierProvider<MessagesNotifier, List<MessageModel>>((ref) {
  return MessagesNotifier(ref);
});