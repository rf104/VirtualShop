import 'dart:math';

import 'package:flutter/material.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/product_detail_page.dart';
import 'package:virtual_shop/widgets/glass_container.dart';

class VirtualClosetPage extends StatelessWidget {
  final List<Product> products;
  const VirtualClosetPage({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SimilarProducts(products: products),
          // Top gradient overlay for better contrast
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 32,
            left: 16,
            child: ClipOval(
              child: Material(
                color: Colors.black54,
                child: InkWell(
                  splashColor: Colors.white24,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final List<Product> dummyProducts = List.generate(
  5,
  (index) => Product(
    id: 'closet_product_$index',
    authId: 'closet_seller_$index',
    name: 'Product ${index + 1}',
    description: 'This is a description for product ${index + 1}.',
    category: ProductCategory.values[index % ProductCategory.values.length],
    brand: 'Brand ${(index % 3) + 1}',
    price: 99.99 + (index * 10),
    stock: 5 + index,
    condition: ProductCondition.values[index % ProductCondition.values.length],
    weightKg: 0.3 + (index * 0.1),
    dimensions: '15x25x3 cm',
    isFeatured: index % 2 == 0,
    isInStock: true,
    createdAt: DateTime.now().subtract(Duration(days: index * 2)),
    updatedAt: DateTime.now().subtract(Duration(hours: index * 3)),
    image: 'assets/images/demo${index + 1}.jpg',
    rating: 4.0 + (index * 0.2),
    isLoved: false,
  ),
);

class SimilarProducts extends StatefulWidget {
  final List<Product> products;
  const SimilarProducts({super.key, required this.products});

  @override
  State<SimilarProducts> createState() => _SimilarProductsState();
}

class _SimilarProductsState extends State<SimilarProducts>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _angleOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _angleOffset += details.delta.dy * 0.01;
        });
      },
      child: Stack(
        children: [
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Summar Closet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          CustomPaint(size: size, painter: ArcPainter()),
          ...List.generate(widget.products.length, (index) {
            final product = widget.products[index];
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final angle =
                    (pi / 2) +
                    (_controller.value * 2 * pi) +
                    (index * pi / 2.5) +
                    _angleOffset;
                final radius = size.width * 0.8;
                final x = size.width / 2 + radius * cos(angle) * 0.5;
                final y = size.height / 2 + radius * sin(angle) * 0.8;
                final scale = 0.5 + 0.5 * (sin(angle) + 1) / 2;

                return Positioned(
                  left: x - (50 * scale),
                  top: y - (50 * scale),
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailPage(product: product),
                              ),
                            );
                          },
                          child: GlassContainer(
                            width: 100,
                            height: 100,
                            borderRadius: 85,
                            color: Colors.white.withOpacity(0.08),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundImage: AssetImage(product.image),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width * 0.2, 0);
    path.quadraticBezierTo(
      size.width * 1.2,
      size.height * 0.5,
      size.width * 0.2,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
