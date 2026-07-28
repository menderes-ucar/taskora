import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/models/portfolio_item_model.dart';
import '../data/portfolio_repository_provider.dart';

class PortfolioNotifier
    extends AsyncNotifier<List<PortfolioItemModel>> {

  @override
  Future<List<PortfolioItemModel>> build() async {
    return [];
  }

  Future<void> load(String freelancerId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref
          .read(portfolioRepositoryProvider)
          .getByFreelancer(freelancerId);
    });
  }

  Future<void> addPortfolioItem(
      PortfolioItemModel item,
      ) async {
    final repo = ref.read(portfolioRepositoryProvider);

    await repo.addPortfolioItem(item);

    await load(item.freelancerId);
  }

  Future<void> removePortfolioItem(
      String id,
      String freelancerId,
      ) async {
    final repo = ref.read(portfolioRepositoryProvider);

    await repo.removePortfolioItem(id);

    await load(freelancerId);
  }
}

final portfolioProvider =
AsyncNotifierProvider<
    PortfolioNotifier,
    List<PortfolioItemModel>>(
  PortfolioNotifier.new,
);