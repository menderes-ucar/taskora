class JobCategoryHelper {
  static int getCoinCostByCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'yazılım':
      case 'mobil':
      case 'yazilim':
        return 10;
      case 'ui/ux':
      case 'tasarım':
      case 'tasarim':
        return 8;
      case 'grafik tasarım':
      case 'grafik tasarim':
      case 'video':
        return 5;
      case 'sosyal medya':
      default:
        return 3;
    }
  }
}