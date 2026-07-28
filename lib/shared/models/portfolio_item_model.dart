// shared/models/portfolio_item_model.dart içinde olması gereken yapı:
class PortfolioItemModel {
  final String id;
  final String freelancerId;
  final String title;
  final String category;
  final String description;
  final List<String> imageUrls;
  final String status; // 'pending', 'approved', 'rejected'

  const PortfolioItemModel({
    required this.id,
    required this.freelancerId,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrls,
    this.status = 'pending', // Yeni eklenen portföyler varsayılan olarak onay bekler
  });

  factory PortfolioItemModel.fromMap(Map<String, dynamic> map) {
    return PortfolioItemModel(
      id: map['id'] ?? '',
      freelancerId: map['freelancer_id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? const []),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      'freelancer_id': freelancerId,
      'title': title,
      'category': category,
      'description': description,
      'image_urls': imageUrls,
      'status': status, // Veritabanına onay bekliyor olarak yazılır
    };
  }
}