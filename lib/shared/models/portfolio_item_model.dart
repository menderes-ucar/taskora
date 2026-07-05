class PortfolioItemModel {
  final String id;
  final String freelancerId;
  final String title;
  final String category;
  final String description;
  final List<String> imageUrls;
  final DateTime createdAt;

  PortfolioItemModel({
    required this.id,
    required this.freelancerId,
    required this.title,
    required this.category,
    required this.description,
    this.imageUrls = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  PortfolioItemModel copyWith({
    String? id,
    String? freelancerId,
    String? title,
    String? category,
    String? description,
    List<String>? imageUrls,
    DateTime? createdAt,
  }) {
    return PortfolioItemModel(
      id: id ?? this.id,
      freelancerId: freelancerId ?? this.freelancerId,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}