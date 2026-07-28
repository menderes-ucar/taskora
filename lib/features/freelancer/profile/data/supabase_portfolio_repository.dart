import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/models/portfolio_item_model.dart';
import 'portfolio_repository.dart';

class SupabasePortfolioRepository implements PortfolioRepository {
  final SupabaseClient _supabase;

  SupabasePortfolioRepository(this._supabase);

  static const _table = 'portfolio';

  @override
  Future<List<PortfolioItemModel>> getByFreelancer(
      String freelancerId,
      ) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('freelancer_id', freelancerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (e) => PortfolioItemModel.fromMap(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }

  @override
  Future<void> addPortfolioItem(
      PortfolioItemModel item,
      ) async {
    await _supabase
        .from(_table)
        .insert(item.toInsertMap());
  }

  @override
  Future<void> removePortfolioItem(
      String id,
      ) async {
    await _supabase
        .from(_table)
        .delete()
        .eq('id', id);
  }
}