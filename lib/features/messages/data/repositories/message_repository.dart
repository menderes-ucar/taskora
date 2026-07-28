import '../../../../shared/models/message_model.dart';

abstract class MessageRepository {
  Future<List<MessageModel>> getAllMessages();

  Future<List<MessageModel>> getMessagesForConversation(String conversationId);

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  });

  Future<void> sendProposalMessage({
    required String senderId,
    required String receiverId,
    required String proposalId,
    required double amount,
    required int deliveryDays,
    required String description,
    String proposalStatus = 'pending',
  });

  Future<void> updateProposalMessageStatus({
    required String proposalId,
    required String status,
  });
}