import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/message_model.dart';
import 'message_repository.dart';

class SupabaseMessageRepository implements MessageRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<MessageModel>> getAllMessages() async {
    final response = await _client
        .from('messages')
        .select()
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => MessageModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<MessageModel>> getMessagesForConversation(
      String conversationId,
      ) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => MessageModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conversationId = senderId.compareTo(receiverId) < 0
        ? '${senderId}_$receiverId'
        : '${receiverId}_$senderId';

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': trimmed,
      'type': 'text',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> sendProposalMessage({
    required String senderId,
    required String receiverId,
    required String proposalId,
    required double amount,
    required int deliveryDays,
    required String description,
    String proposalStatus = 'pending',
  }) async {
    final conversationId = senderId.compareTo(receiverId) < 0
        ? '${senderId}_$receiverId'
        : '${receiverId}_$senderId';

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': 'Özel teklif gönderildi',
      'type': 'proposal',
      'proposal_id': proposalId,
      'proposal_amount': amount,
      'proposal_delivery_days': deliveryDays,
      'proposal_description': description.trim(),
      'proposal_status': proposalStatus,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateProposalMessageStatus({
    required String proposalId,
    required String status,
  }) async {
    await _client
        .from('messages')
        .update({'proposal_status': status})
        .eq('proposal_id', proposalId);
  }

  // 🚀 REAL-TIME STREAM: Tüm mesajlar tablosundaki değişiklikleri anlık yakalar
  Stream<List<MessageModel>> streamAllUserMessages(String userId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((maps) => maps
        .map((map) => MessageModel.fromMap(map))
        .where((m) => m.senderId == userId || m.receiverId == userId)
        .toList());
  }
}