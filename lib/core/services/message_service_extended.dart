// 🚀 MESSAGE SERVICE EXTENSION - COİN IŞLEMLERI

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/coin/data/services/coin_service.dart';
import '../../shared/models/message_model.dart';
import '../../shared/models/coin_model.dart';


/// İlk mesaj gönderirken coin işlemleri
Future<String> sendFirstMessageWithCoinDeduction({
  required SupabaseClient supabase,
  required MessageModel message,
  required int coinCost,
}) async {
  try {
    final coinService = SupabaseCoinService(supabase);

    // 1. Freelancer'ın coin bakiyesini kontrol et (sadece freelancer mesaj gönderirse coin ödeyecek)
    // Burada sender'ın freelancer olduğu varsayılıyor
    final userBalance = await coinService.getUserCoinBalance(message.senderId);
    if (userBalance < coinCost) {
      throw Exception('Yeterli coin bulunmamaktadır. Gerekli: $coinCost, Mevcut: $userBalance');
    }

    // 2. Mesajı is_first_message = true ile kaydet
    final messageWithFirstFlag = message.copyWith(isFirstMessage: true);

    final response = await supabase
        .from('messages')
        .insert(messageWithFirstFlag.toMap())
        .select()
        .single();

    final messageId = response['id'] as String;

    // 3. Coin'i deduct et
    await coinService.deductCoin(
      message.senderId,
      coinCost,
      CoinTransactionType.message,
      relatedId: messageId,
      description: 'Mesaj gönderme',
    );

    return messageId;
  } catch (e) {
    print('❌ sendFirstMessageWithCoinDeduction error: $e');
    rethrow;
  }
}

/// Sohbetin ilk mesajı mı kontrol et
Future<bool> isFirstMessageInConversation({
  required SupabaseClient supabase,
  required String conversationId,
  required String senderId,
}) async {
  try {
    final response = await supabase
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .eq('sender_id', senderId)
        .limit(1);

    return (response as List).isEmpty;
  } catch (e) {
    print('❌ isFirstMessageInConversation error: $e');
    return false;
  }
}

/// Sohbette kaç mesaj var kontrol et
Future<int> getConversationMessageCount({
  required SupabaseClient supabase,
  required String conversationId,
}) async {
  try {
    final response = await supabase
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId);

    return (response as List).length;
  } catch (e) {
    print('❌ getConversationMessageCount error: $e');
    return 0;
  }
}
