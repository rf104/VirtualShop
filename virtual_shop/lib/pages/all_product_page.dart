import 'package:flutter/material.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';
import 'package:virtual_shop/utils/product_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllProductPage extends StatefulWidget {
  const AllProductPage({super.key});

  @override
  State<AllProductPage> createState() => _AllProductPageState();
}

class _AllProductPageState extends State<AllProductPage> {
  List<Product> _products = const [];
  String _query = '';
  bool _loading = true;
  String? _error;

  // Filter chip placeholders removed for now

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ProductRepository.fetchAll();
      setState(() {
        _products = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              // const SizedBox(height: 20),
              // _buildFilterChips(),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Shop',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Row(
          children: [_buildHeaderButton('Items', _products.length.toString())],
        ),
      ],
    );
  }

  Widget _buildHeaderButton(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 5),
          Text(
            count,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _query = v.trim()),
      decoration: const InputDecoration(
        hintText: 'Type to search...',
        prefixIcon: Icon(Icons.search),
        suffixIcon: Icon(Icons.filter_list),
      ),
    );
  }

  // Widget _buildFilterChips() {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       children: [
  //         _buildFilterChip('Weather', _selectedWeather, (newValue) {
  //           setState(() {
  //             _selectedWeather = newValue;
  //           });
  //         }),
  //         const SizedBox(width: 10),
  //         _buildFilterChip('Temp', _selectedTemp, (newValue) {
  //           setState(() {
  //             _selectedTemp = newValue;
  //           });
  //         }),
  //         const SizedBox(width: 10),
  //         _buildFilterChip('Event', _selectedEvent, (newValue) {
  //           setState(() {
  //             _selectedEvent = newValue;
  //           });
  //         }),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFilterChip(
  //   String label,
  //   String value,
  //   ValueChanged<String> onSelected,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).inputDecorationTheme.fillColor,
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Row(
  //       children: [
  //         Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
  //         const SizedBox(width: 4),
  //         const Icon(Icons.close, size: 14),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load products',
              style: TextStyle(color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final filtered = _products
        .where((p) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              (p.brand?.toLowerCase().contains(q) ?? false);
        })
        .toList(growable: false);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          child: Hero(
            tag: product.image,
            child: ProductCard(product: product),
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _AdaptiveImage(image: product.image),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          product.category,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '৳${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdaptiveImage extends StatelessWidget {
  final String image;
  const _AdaptiveImage({required this.image});

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    // Estimate on-screen width for thumbnail cache sizing
    double screenWidth = MediaQuery.of(context).size.width;
    // Grid: 2 columns, horizontal padding 16*2 and spacing 16
    double itemLogicalWidth = (screenWidth - 32 - 16) / 2;
    final double pxW =
        (itemLogicalWidth) * MediaQuery.of(context).devicePixelRatio;
    final int? cacheWidth = (pxW.isFinite && pxW > 0) ? pxW.round() : null;
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        width: double.infinity,
        memCacheWidth: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[700],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 40),
          ),
        ),
      );
    }
    return Image.asset(
      image,
      fit: BoxFit.cover,
      width: double.infinity,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey[700],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}
