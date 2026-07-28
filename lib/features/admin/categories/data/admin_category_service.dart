import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Tüm kategorileri çek
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Kategoriler alınamadı: $e');
    }
  }

  // Yeni kategori ekle
  Future<void> addCategory(String categoryName) async {
    try {
      await _supabase.from('categories').insert({'name': categoryName});
    } catch (e) {
      throw Exception('Kategori eklenirken hata oluştu: $e');
    }
  }

  // Kategori sil
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('categories').delete().eq('id', categoryId);
    } catch (e) {
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }
}