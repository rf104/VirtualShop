class Product {
  final String id;
  final String name;
  final String image; // Primary image URL or asset path
  final List<String> images; // All image URLs if available
  final double rating; // Average rating if available
  final int? ratingCount;
  final double price;
  final String category;
  final String description;
  final String? brand;
  final int? stock;
  final String? condition;
  final double? weightKg;
  final String? dimensions;
  final bool? isFeatured;
  final bool? isInStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Legacy/UX fields retained for UI chips; may be empty
  final String weather;
  final String temp;
  final String event;
  bool isLoved;

  Product({
    this.id = '',
    required this.name,
    required this.image,
    this.images = const [],
    this.rating = 0,
    this.ratingCount,
    required this.price,
    required this.category,
    required this.description,
    this.brand,
    this.stock,
    this.condition,
    this.weightKg,
    this.dimensions,
    this.isFeatured,
    this.isInStock,
    this.createdAt,
    this.updatedAt,
    this.weather = '',
    this.temp = '',
    this.event = '',
    this.isLoved = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    List<String> extractImages(Map<String, dynamic> map) {
      final dynamic imgsDyn = map['images'] ?? map['product_images'];
      if (imgsDyn is List) {
        // Could be a list of urls or list of objects with image_url
        final List<String> urls = [];
        for (final e in imgsDyn) {
          if (e is String) {
            urls.add(e);
          } else if (e is Map) {
            final u = e['image_url'] ?? e['url'] ?? e['src'];
            if (u != null && u.toString().isNotEmpty) urls.add(u.toString());
          }
        }
        return urls;
      }
      return const [];
    }

    String pickImage(Map<String, dynamic> map) {
      // Prefer explicit primary fields
      final img = map['image_url'] ?? map['image'] ?? map['thumbnail'] ?? '';
      if (img != null && img.toString().isNotEmpty) {
        return img.toString();
      }
      // Or derive from images array
      final imgs = extractImages(map);
      if (imgs.isNotEmpty) return imgs.first;
      return '';
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['product_name']?.toString() ??
          'Product',
      image: pickImage(json),
      images: extractImages(json),
      rating: toDouble(
        json['rating'] ?? json['avg_rating'] ?? json['rating_avg'],
        0,
      ),
      ratingCount: toInt(
        json['rating_count'] ?? json['reviews_count'] ?? json['count_reviews'],
      ),
      price: toDouble(json['price'], 0),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      brand: json['brand']?.toString(),
      stock: toInt(json['stock']),
      condition: json['condition']?.toString(),
      weightKg: toDouble(json['weight_kg'], 0) == 0 && json['weight_kg'] == null
          ? null
          : toDouble(json['weight_kg']),
      dimensions: json['dimensions']?.toString(),
      isFeatured: json['is_featured'] as bool?,
      isInStock: json['is_in_stock'] as bool?,
      createdAt: toDate(json['created_at']),
      updatedAt: toDate(json['updated_at']),
      // Optional UX extras if backend ever provides them
      weather: json['weather']?.toString() ?? '',
      temp: json['temp']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
    );
  }
}
