import 'dart:convert'; // For JSON decoding
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:virtual_shop/models/product.dart'; // Make sure this path is correct
import 'package:virtual_shop/pages/product_detail_page.dart';

class MyProductsSheet extends StatefulWidget {
  final String sellerId; // Pass the seller ID to fetch products for
  const MyProductsSheet({super.key, required this.sellerId});

  @override
  State<MyProductsSheet> createState() => _MyProductsSheetState();
}

class _MyProductsSheetState extends State<MyProductsSheet> {
  String _selectedFilter = "All";
  List<Product> _allProducts = []; // Store all fetched products
  List<Product> _filteredProducts = []; // Products shown based on filter
  bool _isLoading = true;
  String? _errorMessage;

  String get _baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    String raw = (fromServer?.isNotEmpty == true)
        ? fromServer!
        : (fromBackend?.isNotEmpty == true
              ? fromBackend!
              : 'http://127.0.0.1:8000');
    // Remove accidental whitespace after scheme like 'http:// 127.0.0.1:8000'
    raw = raw.replaceFirst(RegExp(r'^(https?://)\s+'), r'$1');
    String url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    // Map localhost to Android emulator loopback if applicable
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final uri = Uri.parse(url);
        if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
          url = uri
              .replace(host: dotenv.env['hostIp'] ?? '192.168.0.106')
              .toString();
        }
      }
    } catch (_) {}
    return url;
  }

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
  }

  Future<void> _fetchSellerProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Use the same base URL pattern as ImageSearchService
    final String apiUrl = "$_baseUrl/sellers/${widget.sellerId}/products";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'];
        _allProducts = productsJson
            .map((json) => Product.fromJson(json))
            .toList();
        _applyFilter(); // Apply initial filter after fetching
      } else {
        setState(() {
          _errorMessage =
              "Failed to load products: ${response.statusCode} - ${response.reasonPhrase}";
          print("Error: ${response.body}");
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching products: $e";
        print("Exception: $e");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == "All") {
        _filteredProducts = List.from(_allProducts); // Create a new list
      } else if (_selectedFilter == "In Stock") {
        // Based on the 'stock' and 'is_in_stock' fields from your DB schema
        _filteredProducts = _allProducts
            .where((p) => p.isInStock && p.stock > 10)
            .toList();
      } else if (_selectedFilter == "Low Stock") {
        _filteredProducts = _allProducts
            .where((p) => p.isInStock && p.stock <= 10 && p.stock > 0)
            .toList();
      } else if (_selectedFilter == "Out of Stock") {
        _filteredProducts = _allProducts
            .where((p) => !p.isInStock || p.stock == 0)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                                "Overview for your ${_filteredProducts.length} products",
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
                                _applyFilter();
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
                                _applyFilter();
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
                                _applyFilter();
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
                                _applyFilter();
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : _filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          "No products found for this filter.",
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
                            itemCount: _filteredProducts.length,
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
                              final product = _filteredProducts[i];
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

// Filter chip widget for filter selection
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff667eea) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xff667eea) : Colors.grey[700]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
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

  // Helper to get stock status text based on actual stock
  String _getStockStatusText(Product product) {
    if (!product.isInStock || product.stock == 0) return "Out of Stock";
    if (product.stock <= 10) return "Low Stock";
    return "In Stock";
  }

  // Helper to get stock color based on actual stock
  Color _getStockColor(Product product) {
    if (!product.isInStock || product.stock == 0) {
      return const Color(0xffE53E3E); // Red
    }
    if (product.stock <= 10) return const Color(0xffED8936); // Orange
    return const Color(0xff38A169); // Green
  }

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
              // Image - Now using NetworkImage for dynamic content
              Positioned.fill(
                child: Image.network(
                  product.image, // Use product.image (expected to be a URL)
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[700],
                      child: Icon(
                        _getCategoryIcon(
                          product.category.toString().split('.').last,
                        ), // Use enum to string
                        color: Colors.white,
                        size: 40,
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
              // Stock status
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStockColor(product),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStockStatusText(product),
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
                                // Assuming we want to show a rating, but your DB schema doesn't have it.
                                // You might need to add 'rating' to your Product model and DB if desired.
                                // For now, I'll display a placeholder or derive from another field if you clarify.
                                // Or, you can remove this section if ratings are not a feature.
                                "4.5", // Placeholder
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
                        content: Text(
                          'Editing ${product.name} (ID: ${product.id})',
                        ),
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
                    // Toggle love status - This will need to be handled by local state or a state management solution
                    // For now, it won't persist if product objects are re-fetched.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Toggling love for ${product.name}'),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
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
}

// Helper function to get category icon - updated to work with Product enum
IconData _getCategoryIcon(String? category) {
  switch (category?.toLowerCase()) {
    case 'cozywear':
      return Icons.emoji_people;
    case 'footwear':
      return Icons.directions_walk;
    case 'formalwear':
      return Icons.checkroom;
    case 'regularwear':
      return Icons.style;
    default:
      return Icons.shopping_bag;
  }
}

// The _buildProductItem function is no longer needed as we are using GridView.builder with _ProductCard.
// You can remove it.
