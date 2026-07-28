import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/message_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/message_repository_provider.dart';
import '../../data/repositories/supabase_message_repository.dart';

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
    _listenGlobalMessages();
  }

  final Ref ref;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  final Map<String, UserModel> _userCache = {};

  MessageRepository get _repository => ref.read(messageRepositoryProvider);

  Future<void> loadMessages() async {
    state = await _repository.getAllMessages();
    _prefetchUsers();
  }

  void _listenGlobalMessages() {
    final repo = _repository;
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    if (repo is SupabaseMessageRepository) {
      _messagesSubscription?.cancel();
      _messagesSubscription = repo
          .streamAllUserMessages(currentUser.id)
          .listen((updatedMessages) {
        state = updatedMessages;
        _prefetchUsers();
      });
    }
  }

  // 🚀 SAAS PRO KORUMA: Karşı taraftaki kullanıcıların gerçek adlarını profiles tablosundan çeker
  Future<void> _prefetchUsers() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    final otherUserIds = state
        .map((m) => m.senderId == currentUser.id ? m.receiverId : m.senderId)
        .toSet()
        .where((id) => !_userCache.containsKey(id))
        .toList();

    if (otherUserIds.isEmpty) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .filter('id', 'in', otherUserIds);

      for (final profile in (response as List)) {
        final user = UserModel.fromMap(profile);
        _userCache[user.id] = user;
      }
    } catch (_) {}
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
  }

  Future<void> updateProposalMessageStatus({
    required String proposalId,
    required String status,
  }) async {
    await _repository.updateProposalMessageStatus(
      proposalId: proposalId,
      status: status,
    );
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

      // 🚀 GERÇEK VERİ YÜKLEME: Cache'de yoksa fallback, varsa gerçek isim gösterilir
      final otherUser = _userCache[otherUserId] ??
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
          lastSeenText: 'Aktif Sohbet',
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

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

final messagesProvider =
StateNotifierProvider<MessagesNotifier, List<MessageModel>>((ref) {
  return MessagesNotifier(ref);
});