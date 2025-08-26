import 'package:flutter/material.dart';
import '../utils/product_service_rf.dart';
import '../models/product_rf.dart' as rf_product;
import '../models/product.dart' as main_product;
import '../pages/product_detail_page.dart';

class BestSellerWidget extends StatefulWidget {
  const BestSellerWidget({super.key});

  @override
  State<BestSellerWidget> createState() => _BestSellerWidgetState();
}

class _BestSellerWidgetState extends State<BestSellerWidget> {
  late Future<List<rf_product.Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = ProductService().fetchProducts();
  }

  // Convert rf_product.Product to main_product.Product for navigation
  main_product.Product _convertProduct(rf_product.Product rfProduct) {
    return main_product.Product(
      id: rfProduct.id,
      name: rfProduct.name,
      image: rfProduct.imageUrl,
      images: [rfProduct.imageUrl],
      price: rfProduct.price,
      category: rfProduct.category,
      description: rfProduct.description,
      brand: rfProduct.brand,
      stock: rfProduct.stock,
      condition: rfProduct.condition,
      weightKg: rfProduct.weightKg,
      dimensions: rfProduct.dimensions,
      isFeatured: rfProduct.isFeatured,
      isInStock: rfProduct.isInStock,
      rating: 4.5, // Default rating since rf_product.Product doesn't have it
      ratingCount: 10, // Default rating count
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Best Selling Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<rf_product.Product>>(
            future: _futureProducts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No products found"));
              }

              final products = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final item = products[index];
                  return GestureDetector(
                    onTap: () {
                      // Convert rf_product.Product to main_product.Product and navigate
                      final mainProduct = _convertProduct(item);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(product: mainProduct),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl.isNotEmpty 
                                  ? item.imageUrl 
                                  : "https://via.placeholder.com/150",
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.name.isNotEmpty ? item.name : "Unknown Product",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "৳${item.price.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
