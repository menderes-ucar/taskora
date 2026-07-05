import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/data/mock_data.dart';
import '../../../../../shared/models/portfolio_item_model.dart';

class PortfolioNotifier extends StateNotifier<List<PortfolioItemModel>> {
  PortfolioNotifier() : super(List<PortfolioItemModel>.from(MockData.portfolio));

  List<PortfolioItemModel> getByFreelancer(String freelancerId) {
    final items = state
        .where((item) => item.freelancerId == freelancerId)
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  void addPortfolioItem(PortfolioItemModel item) {
    state = [item, ...state];
  }

  void removePortfolioItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final portfolioProvider =
StateNotifierProvider<PortfolioNotifier, List<PortfolioItemModel>>(
      (ref) => PortfolioNotifier(),
);