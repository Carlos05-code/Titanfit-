class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
      };
}
