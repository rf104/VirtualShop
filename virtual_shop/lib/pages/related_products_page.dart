import 'package:flutter/material.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RelatedProductsPage extends StatelessWidget {
  final List<Product> products;
  const RelatedProductsPage({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Related Products'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
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
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _ProductImage(image: product.image),
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
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String image;
  const _ProductImage({required this.image});

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    // Grid thumbnails ~ half screen width on 2-column grid
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemLogicalWidth = (screenWidth - 16 * 2 - 16) / 2;
    final double pxW =
        itemLogicalWidth * MediaQuery.of(context).devicePixelRatio;
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
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[700],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}
