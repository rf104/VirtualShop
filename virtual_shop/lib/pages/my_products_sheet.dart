import 'package:flutter/material.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';

class MyProductsSheet extends StatefulWidget {
  const MyProductsSheet({super.key});

  @override
  State<MyProductsSheet> createState() => _MyProductsSheetState();
}

class _MyProductsSheetState extends State<MyProductsSheet> {
  String _selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    // Using the same Product model as other pages
    final List<Product> products = [
      // Products from AllProductPage
      Product(
        name: 'Winter Shearling Jacket',
        image: 'assets/images/hoodie.jpg',
        rating: 4.1,
        price: 120.00,
        category: 'Cozy Wear',
        weather: 'Rainy',
        temp: '16-22°C',
        event: 'Promenade',
        description:
            'Elevate your winter wardrobe with this luxurious white shearling jacket.',
        // stockStatus: 'Low Stock', // Assuming this is not part of the Product model provided
        // sold: 45, // Assuming this is not part of the Product model provided
      ),
      Product(
        name: 'Casual Chic Hat',
        image: 'assets/images/hat.jpg',
        rating: 4.8,
        price: 85.50,
        category: 'Regular Wear',
        weather: 'Neutral',
        temp: '16-22°C',
        event: 'Promenade',
        description:
            'Step out in style with this casual chic ensemble featuring a trendy hat.',
        // stockStatus: 'In Stock',
        // sold: 120,
      ),
      Product(
        name: 'Urban Explorer Shoes',
        image: 'assets/images/shoe.jpg',
        rating: 4.9,
        price: 215.00,
        category: 'Footwear',
        weather: 'Rainy',
        temp: '16-22°C',
        event: 'Promenade',
        description:
            'Gear up for your next adventure with these durable boots.',
        // stockStatus: 'In Stock',
        // sold: 75,
      ),
      // Products from StoryPage
      Product(
        image: 'assets/images/demo1.jpg',
        name: "Arik's Summer Shirt",
        rating: 4.2,
        price: 75.00,
        category: 'Cozy Wear',
        weather: 'Sunny',
        temp: '25-30°C',
        event: 'Beach',
        description: 'A nice shirt.',
        // stockStatus: 'Low Stock',
        // sold: 60,
      ),
      Product(
        image: 'assets/images/demo2.jpg',
        name: "Arik's Winter Jacket",
        rating: 4.1,
        price: 150.00,
        category: 'Cozy Wear',
        weather: 'Rainy',
        temp: '16-22°C',
        event: 'Promenade',
        description: 'A nice jacket.',
        // stockStatus: 'Low Stock',
        // sold: 40,
      ),
      Product(
        image: 'assets/images/demo3.jpg',
        name: "Arik's Fall Coat",
        rating: 3.9,
        price: 180.00,
        category: 'Cozy Wear',
        weather: 'Cloudy',
        temp: '10-15°C',
        event: 'Walk',
        description: 'A nice coat.',
        // stockStatus: 'Out of Stock',
        // sold: 10,
      ),
      Product(
        name: "Samin's Clothing Set",
        image: 'assets/images/demo4.jpg',
        rating: 4.5,
        price: 300.00,
        category: 'Cozy Wear',
        weather: 'Any',
        temp: 'Any',
        event: 'Any',
        description: 'A nice set.',
        // stockStatus: 'In Stock',
        // sold: 90,
      ),
      Product(
        name: "Aref's Clothing Set",
        image: 'assets/images/demo5.jpg',
        rating: 4.6,
        price: 300.00,
        category: 'Cozy Wear',
        weather: 'Any',
        temp: 'Any',
        event: 'Any',
        description: 'A nice set.',
        // stockStatus: 'In Stock',
        // sold: 95,
      ),
      // Additional fashion items
      Product(
        name: 'Designer Dress',
        image: 'assets/images/dress1.jpg',
        rating: 4.6,
        price: 280.00,
        category: 'Formal Wear',
        weather: 'Any',
        temp: 'Any',
        event: 'Party',
        description: 'Elegant evening dress perfect for special occasions.',
        // stockStatus: 'In Stock',
        // sold: 30,
      ),
      Product(
        name: 'Casual Sneakers',
        image: 'assets/images/sneakers.jpg',
        rating: 4.4,
        price: 95.00,
        category: 'Footwear',
        weather: 'Any',
        temp: 'Any',
        event: 'Casual',
        description: 'Comfortable sneakers for everyday wear.',
        // stockStatus: 'Low Stock',
        // sold: 55,
      ),
    ];

    // Filter products based on selected filter
    // NOTE: The provided Product model does not have stockStatus or sold fields.
    // This filtering logic would need adjustment if those fields are intended.
    // For now, we'll filter based on rating as a proxy for availability,
    // or you can add those fields to your Product model.
    List<Product> filteredProducts = products;
    if (_selectedFilter == "In Stock") {
      // Assuming "In Stock" means rating >= 4.5 for demo purposes
      filteredProducts = products.where((p) => p.rating >= 4.5).toList();
    } else if (_selectedFilter == "Low Stock") {
      // Assuming "Low Stock" means rating >= 4.0 and < 4.5 for demo purposes
      filteredProducts = products
          .where((p) => p.rating >= 4.0 && p.rating < 4.5)
          .toList();
    } else if (_selectedFilter == "Out of Stock") {
      // Assuming "Out of Stock" means rating < 4.0 for demo purposes
      filteredProducts = products.where((p) => p.rating < 4.0).toList();
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.50,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900], // Dark theme
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff667eea), Color(0xff764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "My Products",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Overview for your ${filteredProducts.length} products",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: "All",
                            isSelected: _selectedFilter == "All",
                            onTap: () {
                              setState(() {
                                _selectedFilter = "All";
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: "In Stock",
                            isSelected: _selectedFilter == "In Stock",
                            onTap: () {
                              setState(() {
                                _selectedFilter = "In Stock";
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: "Low Stock",
                            isSelected: _selectedFilter == "Low Stock",
                            onTap: () {
                              setState(() {
                                _selectedFilter = "Low Stock";
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: "Out of Stock",
                            isSelected: _selectedFilter == "Out of Stock",
                            onTap: () {
                              setState(() {
                                _selectedFilter = "Out of Stock";
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Product grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          "No products found",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          GridView.builder(
                            itemCount: filteredProducts.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            itemBuilder: (_, i) {
                              final product = filteredProducts[i];
                              return _ProductCard(product: product);
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff667eea) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xff667eea) : Colors.grey[600]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to ProductDetailPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[800],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.asset(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[700],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Stock status (using rating as proxy since stockStatus is not in the provided model)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStockColor(
                      product.rating,
                    ), // Using rating to determine color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStockStatusText(
                      product.rating,
                    ), // Using rating to determine text
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '৳${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.rating.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    // Handle edit product logic here if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Editing ${product.name}'),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xff667eea),
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Love button (using isLoved from Product model)
              Positioned(
                top: 12,
                right: 55, // Adjusted position to not overlap stock status
                child: GestureDetector(
                  onTap: () {
                    // Toggle love status
                    // Note: This change won't persist across widget rebuilds unless
                    // state management is implemented.
                    // For a real app, you'd likely use Provider or similar.
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      product.isLoved ? Icons.favorite : Icons.favorite_border,
                      color: product.isLoved ? Colors.red : Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to get stock status text based on rating
  String _getStockStatusText(double rating) {
    if (rating >= 4.5) return "In Stock";
    if (rating >= 4.0) return "Low Stock";
    return "Out of Stock";
  }

  // Helper to get stock color based on rating
  Color _getStockColor(double rating) {
    if (rating >= 4.5) return const Color(0xff38A169); // Green
    if (rating >= 4.0) return const Color(0xffED8936); // Orange
    return const Color(0xffE53E3E); // Red
  }
}

// Helper function to get category icon
IconData _getCategoryIcon(String? category) {
  switch (category) {
    case 'Cozy Wear':
      return Icons.emoji_people;
    case 'Footwear':
      return Icons.directions_walk;
    case 'Formal Wear':
      return Icons.checkroom;
    case 'Regular Wear':
      return Icons.style;
    default:
      return Icons.shopping_bag;
  }
}

// This function is not directly used within MyProductsSheet anymore,
// but can be kept if needed elsewhere or for consistency.
Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
  return GestureDetector(
    onTap: () {
      // Convert the product map to Product model
      final productModel = Product(
        name: product['name'] ?? '',
        description: product['description'] ?? 'No description available',
        price: (product['price'] as num?)?.toDouble() ?? 0.0,
        image: product['image'] ?? '',
        category: product['category'] ?? '',
        rating: (product['rating'] as num?)?.toDouble() ?? 0.0,
        weather: product['weather'] ?? 'Any',
        temp: product['temp'] ?? 'Any',
        event: product['event'] ?? 'Casual',
        // isLoved is false by default if not provided
      );

      // Navigate to ProductDetailPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(product: productModel),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  _getCategoryIcon(product['category']),
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['category'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: const Color(0xffFFD700), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      product['rating'].toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        // This assumes 'status' field in the map is 'Active' or 'Sold Out'
                        color: product['status'] == 'Active'
                            ? const Color(0xff38A169)
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product['status'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "৳${product['price']}",
                style: const TextStyle(
                  color: Color(0xff38A169),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${product['sold']} sold", // Assuming 'sold' field exists in map
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    ),
  );
}
