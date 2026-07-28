import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../features/coin/data/services/coin_service.dart';
import '../error/app_exception.dart';
import '../../shared/models/message_model.dart';

import 'message_service_extended.dart';

abstract class IMessageService {
  Future<List<MessageModel>> getMessages(String conversationId, {int page = 1});
  Future<MessageModel> sendMessage(MessageModel message);
  Future<void> deleteMessage(String messageId);
  Future<List<Map<String, dynamic>>> getConversations(String userId);
  Future<Map<String, dynamic>> getOrCreateConversation(
      String userId,
      String otherUserId,
      );
  Stream<MessageModel> listenToMessages(String conversationId);
  Future<void> markAsRead(String conversationId, String userId);
}

class SupabaseMessageService implements IMessageService {
  final SupabaseClient _supabase;

  SupabaseMessageService(this._supabase);

  @override
  Future<List<MessageModel>> getMessages(
      String conversationId, {
        int page = 1,
      }) async {
    try {
      const limit = 50;
      int offset = (page - 1) * limit;

      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return List<MessageModel>.from(
        (response as List).map((msg) => MessageModel.fromMap(msg)),
      );
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      final messageData = {
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'receiver_id': message.receiverId,
        'text': message.text,
        'created_at': DateTime.now().toIso8601String(),
        'is_first_message': false,
      };

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      // Update conversation last_message_at
      await _updateConversationLastMessage(
        message.conversationId,
        message.text,
      );

      return MessageModel.fromMap(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            participant1:participant1_id(id, name, avatar_url),
            participant2:participant2_id(id, name, avatar_url),
            last_message:messages(text, created_at)
          ''')
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Future<Map<String, dynamic>> getOrCreateConversation(
      String userId,
      String otherUserId,
      ) async {
    try {
      // Try to find existing conversation
      final existing = await _supabase
          .from('conversations')
          .select()
          .or(
        'and(participant1_id.eq.$userId,participant2_id.eq.$otherUserId),'
            'and(participant1_id.eq.$otherUserId,participant2_id.eq.$userId)',
      )
          .maybeSingle();

      if (existing != null) {
        return existing;
      }

      // Create new conversation
      final newConv = await _supabase
          .from('conversations')
          .insert({
        'participant1_id': userId,
        'participant2_id': otherUserId,
        'created_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      return newConv;
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  @override
  Stream<MessageModel> listenToMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(
      primaryKey: ['id'],
    )
        .eq('conversation_id', conversationId)
        .map(
          (rows) => rows
          .map(
            (row) => MessageModel.fromMap(
          Map<String, dynamic>.from(row),
        ),
      )
          .toList(),
    )
        .expand((messages) => messages);
  }

  @override
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
    } catch (e) {
      throw ExceptionFactory.create(e, StackTrace.current);
    }
  }

  // 🚀 İlk mesajı gönderirken coin deduct et
  Future<void> sendFirstMessage(MessageModel message) async {
    try {
      final coinService = SupabaseCoinService(_supabase);
      final messageCoinCost = await coinService.getMessageCoinCost();

      // İlk mesajsa coin deduct et
      await sendFirstMessageWithCoinDeduction(
        supabase: _supabase,
        message: message,
        coinCost: messageCoinCost,
      );
    } catch (e) {
      print('❌ sendFirstMessage error: $e');
      rethrow;
    }
  }

  Future<void> _updateConversationLastMessage(
      String conversationId,
      String lastMessage,
      ) async {
    try {
      await _supabase
          .from('conversations')
          .update({
        'last_message_at': DateTime.now().toIso8601String(),
        'last_message': lastMessage,
      })
          .eq('id', conversationId);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
