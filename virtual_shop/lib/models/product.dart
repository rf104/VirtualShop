// lib/models/product.dart
// (Assuming this file exists or you'll create it)

import 'package:flutter/material.dart';

enum ProductCategory {
  electronics,
  fashion,
  homeAndGarden,
  sports,
  books,
  toys,
  beauty,
  automotive,
  health,
  foodAndBeverages,
  unspecified,
}

enum ProductCondition {
  newCondition, // Renamed to avoid keyword conflict
  used,
  refurbished,
  // Add other conditions from your `public.product_condition` enum
}

class Product {
  final String id;
  final String authId; // Seller's auth_id
  final String name;
  final String description;
  final ProductCategory category;
  final String? brand;
  final double price;
  final int stock;
  final ProductCondition condition;
  final double? weightKg;
  final String? dimensions;
  final bool isFeatured;
  final bool isInStock;
  final DateTime createdAt;
  final DateTime updatedAt;
  // You might also want to include image URLs, if your DB stores them in the products table
  // For now, I'll keep 'image' as a simple String for asset paths,
  // but in a real app, it would be a network URL.
  final String image;
  final double rating;
  bool isLoved; // For local UI state, not necessarily from DB

  Product({
    required this.id,
    required this.authId,
    required this.name,
    required this.description,
    required this.category,
    this.brand,
    required this.price,
    required this.stock,
    required this.condition,
    this.weightKg,
    this.dimensions,
    required this.isFeatured,
    required this.isInStock,
    required this.createdAt,
    required this.updatedAt,
    required this.image, // Placeholder for image URL
    required this.rating,
    this.isLoved = false,
  });

  // Factory constructor to create a Product from a JSON map (from your API)
  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to parse category string to enum
    ProductCategory parseCategory(String categoryStr) {
      debugPrint('Parsing category: $categoryStr');
      final normalized = categoryStr
          .toLowerCase()
          .replaceAll('&', 'and')
          .replaceAll(RegExp(r'[^a-z]'), '');
      switch (normalized) {
        case 'electronics':
          return ProductCategory.electronics;
        case 'fashion':
          return ProductCategory.fashion;
        case 'homeandgarden':
          return ProductCategory.homeAndGarden;
        case 'sports':
          return ProductCategory.sports;
        case 'books':
          return ProductCategory.books;
        case 'toys':
          return ProductCategory.toys;
        case 'beauty':
          return ProductCategory.beauty;
        case 'automotive':
          return ProductCategory.automotive;
        case 'health':
          return ProductCategory.health;
        case 'foodandbeverages':
        case 'foodbeverages':
          return ProductCategory.foodAndBeverages;
        default:
          return ProductCategory.unspecified;
      }
    }

    // Helper to parse condition string to enum
    ProductCondition parseCondition(String conditionStr) {
      switch (conditionStr.toLowerCase()) {
        case 'new':
          return ProductCondition.newCondition;
        case 'used':
          return ProductCondition.used;
        case 'refurbished':
          return ProductCondition.refurbished;
        // Add more cases as per your product_condition enum in Supabase
        default:
          return ProductCondition.newCondition; // Default or error
      }
    }

    return Product(
      id: json['id'],
      authId: json['auth_id'],
      name: json['name'],
      description: json['description'],
      category: parseCategory(json['category']?.toString() ?? ''),
      brand: json['brand'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      condition: parseCondition(json['condition']?.toString() ?? ''),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      dimensions: json['dimensions'],
      isFeatured: json['is_featured'],
      isInStock: json['is_in_stock'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // Assuming 'image' field for network URL for simplicity.
      // You might have a separate table for product images.
      // For now, I'll use a placeholder if 'image_url' isn't directly in products table.
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      image: json['image_url'] ?? 'assets/images/placeholder.jpg',
      isLoved:
          json['is_loved'] ??
          false, // Assuming is_loved can come from DB or defaults
    );
  }
}
