import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AdminAnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Duyurular alınamadı: $e');
    }
  }

  // 🚀 SAAS ENTEGRASYONU: Duyuru eklendiğinde profiller tablosundan hedef kitle çekilip otomatik bildirim üretilir.
  Future<void> sendAnnouncement({
    required String title,
    required String content,
    required String targetRole, // 'all', 'freelancer', 'employer'
  }) async {
    try {
      // 1. Duyuru kaydı oluştur
      await _supabase.from('announcements').insert({
        'title': title,
        'content': content,
        'target_role': targetRole,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Hedef kitledeki kullanıcıları çek
      var query = _supabase.from('profiles').select('id');
      if (targetRole != 'all') {
        query = query.eq('role', targetRole);
      }

      final profiles = await query;

      // 3. Kullanıcıların bildirim merkezine yaz
      final notifications = (profiles as List).map((p) {
        return {
          'id': const Uuid().v4(),
          'user_id': p['id'],
          'title': '📢 $title',
          'body': content,
          'type': 'systemAnnouncement',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      if (notifications.isNotEmpty) {
        await _supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      throw Exception('Duyuru gönderilirken hata oluştu: $e');
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _supabase.from('announcements').delete().eq('id', id);
    } catch (e) {
      throw Exception('Duyuru silinirken hata oluştu: $e');
    }
  }
}