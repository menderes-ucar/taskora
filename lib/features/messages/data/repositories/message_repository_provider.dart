import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'message_repository.dart';
import 'supabase_message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return SupabaseMessageRepository();
});