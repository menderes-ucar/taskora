import '../../../../../shared/models/portfolio_item_model.dart';

abstract class PortfolioRepository {
  Future<List<PortfolioItemModel>> getByFreelancer(
      String freelancerId,
      );

  Future<void> addPortfolioItem(
      PortfolioItemModel item,
      );

  Future<void> removePortfolioItem(
      String id,
      );
}