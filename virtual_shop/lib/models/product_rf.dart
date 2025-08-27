class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String brand;
  final double price;
  final int stock;
  final String condition;
  final String? dimensions;
  final double weightKg;
  final bool isFeatured;
  final bool isInStock;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.brand,
    required this.price,
    required this.stock,
    required this.condition,
    this.dimensions,
    required this.weightKg,
    required this.isFeatured,
    required this.isInStock,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      brand: json['brand'],
      price: (json['price'] as num).toDouble(),   // safe cast
      stock: json['stock'] ?? 0,
      condition: json['condition'],
      dimensions: json['dimensions'],
      weightKg: (json['weight_kg'] as num).toDouble(), // fix here ✅
      isFeatured: json['is_featured'],
      isInStock: json['is_in_stock'],
      imageUrl: json['image_url'],
    );
  }
}
